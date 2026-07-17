<#
    Syncs an offline repository of Windows Server Cumulative Updates (LCU)
    and Servicing Stack Updates (SSU) from the Microsoft Update Catalog to
    NFS-backed storage, pruning anything that no longer matches the
    configured retention policy.

    - Query the Microsoft Update Catalog (MSCatalogLTS) per product/kind
    - Diff against the remote manifest.json to find new/obsolete files
    - Download only what's new, push it over rsync/SSH
    - Remove anything remote that's no longer in the desired set
    - Write back an updated manifest.json

    Expects on PATH: pwsh, rsync, ssh
    Expects environment variables: WINUPDATE_REPO_HOST, WINUPDATE_REPO_USER, WINUPDATE_REPO_PATH

    Name:         scripts/winupdate-sync/sync.ps1
    Author:       Michael Poore (@mpoore)
    URL:          https://github.com/mpoore/packer
#>

$ErrorActionPreference = "Stop"

### --- Configuration --- ###
$configPath = Join-Path $PSScriptRoot "config.psd1"
$config = Import-PowerShellDataFile -Path $configPath

$repoHost = $env:WINUPDATE_REPO_HOST
$repoUser = $env:WINUPDATE_REPO_USER
$repoPath = $env:WINUPDATE_REPO_PATH
if (-not $repoHost -or -not $repoUser -or -not $repoPath) {
    throw "WINUPDATE_REPO_HOST, WINUPDATE_REPO_USER and WINUPDATE_REPO_PATH must all be set."
}
$remote = "$repoUser@$repoHost"

# Set WINUPDATE_SSH_DEBUG=true to get verbose ssh/rsync auth negotiation output
# in the job log while diagnosing a connection problem.
$sshDebug = $env:WINUPDATE_SSH_DEBUG -eq 'true'
$sshArgs = if ($sshDebug) { @('-v') } else { @() }
$rsyncRsh = if ($sshDebug) { 'ssh -v' } else { 'ssh' }

$stagingRoot = Join-Path ([System.IO.Path]::GetTempPath()) "winupdate-staging"
if (Test-Path $stagingRoot) { Remove-Item $stagingRoot -Recurse -Force }
New-Item -ItemType Directory -Path $stagingRoot | Out-Null

### --- Catalog module --- ###
if (-not (Get-Module -ListAvailable -Name MSCatalogLTS)) {
    Write-Host "Installing MSCatalogLTS module..."
    Install-Module -Name MSCatalogLTS -Scope CurrentUser -Force -Confirm:$false
}
Import-Module MSCatalogLTS

### --- Helpers --- ###
function Get-KbNumber {
    param([string]$Title)
    if ($Title -match 'KB(\d+)') { return "KB$($Matches[1])" }
    throw "Could not extract a KB number from update title: $Title"
}

function Get-DesiredUpdates {
    param($ProductConfig)

    $results = [System.Collections.Generic.List[object]]::new()
    foreach ($kind in @('Lcu', 'Ssu')) {
        $search = $ProductConfig["${kind}Search"]
        Write-Host "Querying catalog: $search (from $($ProductConfig.CutoffDate))"
        $catalogResults = Get-MSCatalogUpdate -Search $search -FromDate $ProductConfig.CutoffDate `
            -Architecture $ProductConfig.Arch -UpdateType "Security Updates" |
            Sort-Object LastUpdated -Descending

        # Keep the latest N distinct monthly releases (by KB) for this product/kind.
        $kept = $catalogResults | Select-Object -First $config.RetentionCount
        foreach ($u in $kept) {
            $kb = Get-KbNumber -Title $u.Title
            $results.Add([pscustomobject]@{
                Product     = $ProductConfig.Name
                Arch        = $ProductConfig.Arch
                Kind        = $kind
                Kb          = $kb
                Title       = $u.Title
                Guid        = $u.Guid
                LastUpdated = $u.LastUpdated
                # A directory, not a single file: -DownloadAll can pull down more
                # than one file for a single update (e.g. a prerequisite package).
                RelativePath = "$($ProductConfig.Name)/$($ProductConfig.Arch)/${kind}_${kb}"
            })
        }
    }
    return $results
}

function Get-RemoteManifest {
    if ($sshDebug) {
        $json = & ssh @sshArgs $remote "cat '$repoPath/manifest.json' 2>/dev/null"
    }
    else {
        $json = & ssh $remote "cat '$repoPath/manifest.json' 2>/dev/null" 2>$null
    }
    if (-not $json) { return @() }
    return $json | ConvertFrom-Json
}

function Remove-RemoteFiles {
    param([string[]]$RelativePaths)
    if ($RelativePaths.Count -eq 0) { return }

    $script = ($RelativePaths | ForEach-Object {
        "rm -rf -- '$repoPath/$_'"
    }) -join "`n"
    $script | & ssh @sshArgs $remote "bash -s"
    if ($LASTEXITCODE -ne 0) { throw "Failed to remove obsolete remote files (exit $LASTEXITCODE)." }
}

function Push-Manifest {
    param([object[]]$Entries)
    $manifestPath = Join-Path $stagingRoot "manifest.json"
    $Entries | ConvertTo-Json -Depth 5 | Set-Content -Path $manifestPath
    & rsync -avz -e $rsyncRsh $manifestPath "${remote}:$repoPath/manifest.json"
    if ($LASTEXITCODE -ne 0) { throw "rsync of manifest.json failed (exit $LASTEXITCODE)." }
}

### --- Build desired set --- ###
$desired = [System.Collections.Generic.List[object]]::new()
foreach ($product in $config.Products) {
    Get-DesiredUpdates -ProductConfig $product | ForEach-Object { $desired.Add($_) }
}

### --- Diff against remote manifest --- ###
$remoteManifest = Get-RemoteManifest
$remoteByPath = @{}
foreach ($entry in $remoteManifest) { $remoteByPath[$entry.RelativePath] = $entry }

$desiredByPath = @{}
foreach ($entry in $desired) { $desiredByPath[$entry.RelativePath] = $entry }

$toDownload = $desired | Where-Object { -not $remoteByPath.ContainsKey($_.RelativePath) }
$toDelete = $remoteManifest | Where-Object { -not $desiredByPath.ContainsKey($_.RelativePath) }

Write-Host "Desired: $($desired.Count)  Already present: $($desired.Count - $toDownload.Count)  New: $($toDownload.Count)  Obsolete: $($toDelete.Count)"

# `$confirmed` tracks what the remote manifest should say is actually present.
# It's updated and pushed after every step below, so a mid-run failure (crashed
# pod, network blip, resource limit) leaves the remote manifest matching remote
# reality — the next run's diff picks up exactly where this one left off,
# instead of re-downloading everything from scratch.
$confirmed = [System.Collections.Generic.List[object]]::new()
$deletePaths = $toDelete | Select-Object -ExpandProperty RelativePath
foreach ($entry in $remoteManifest) {
    if ($entry.RelativePath -notin $deletePaths) { $confirmed.Add($entry) }
}

### --- Prune obsolete files first, so it isn't skipped if downloads fail --- ###
if ($toDelete.Count -gt 0) {
    Write-Host "Pruning $($toDelete.Count) obsolete file(s)..."
    Remove-RemoteFiles -RelativePaths $deletePaths
    Push-Manifest -Entries $confirmed
}

### --- Download and push new updates one at a time --- ###
# Each item is downloaded, pushed and dropped from local disk before moving to
# the next, so peak local (ephemeral) storage use is one update's files, not
# the whole batch — and a bad/unavailable item doesn't block the rest.
$downloaded = 0
foreach ($item in $toDownload) {
    $itemDir = Join-Path $stagingRoot $item.RelativePath
    New-Item -ItemType Directory -Path $itemDir -Force | Out-Null
    try {
        Write-Host "Downloading $($item.Kb) ($($item.Product)/$($item.Kind))..."
        Save-MSCatalogUpdate -Guid $item.Guid -Destination $itemDir -DownloadAll

        & rsync -avz -e $rsyncRsh "$itemDir/" "${remote}:$repoPath/$($item.RelativePath)/"
        if ($LASTEXITCODE -ne 0) { throw "rsync push failed for $($item.Kb) (exit $LASTEXITCODE)." }

        $confirmed.Add($item)
        Push-Manifest -Entries $confirmed
        $downloaded++
    }
    catch {
        Write-Warning "Skipping $($item.Kb) ($($item.Product)/$($item.Kind)): $_"
    }
    finally {
        Remove-Item $itemDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Sync complete: $downloaded downloaded, $($toDelete.Count) pruned, $($desired.Count - $toDownload.Count) unchanged."
