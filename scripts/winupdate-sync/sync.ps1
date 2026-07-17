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
                RelativePath = "$($ProductConfig.Name)/$($ProductConfig.Arch)/${kind}_${kb}.msu"
            })
        }
    }
    return $results
}

function Get-RemoteManifest {
    $json = & ssh $remote "cat '$repoPath/manifest.json' 2>/dev/null" 2>$null
    if (-not $json) { return @() }
    return $json | ConvertFrom-Json
}

function Remove-RemoteFiles {
    param([string[]]$RelativePaths)
    if ($RelativePaths.Count -eq 0) { return }

    $script = ($RelativePaths | ForEach-Object {
        "rm -f -- '$repoPath/$_'"
    }) -join "`n"
    $script | & ssh $remote "bash -s"
    if ($LASTEXITCODE -ne 0) { throw "Failed to remove obsolete remote files (exit $LASTEXITCODE)." }
}

function Push-Staging {
    param([string]$LocalDir)
    & rsync -avz -e ssh "$LocalDir/" "${remote}:$repoPath/"
    if ($LASTEXITCODE -ne 0) { throw "rsync push failed (exit $LASTEXITCODE)." }
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

### --- Download new updates --- ###
foreach ($item in $toDownload) {
    $destDir = Join-Path $stagingRoot (Split-Path $item.RelativePath -Parent)
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    Write-Host "Downloading $($item.Kb) ($($item.Product)/$($item.Kind))..."
    $updateObj = Get-MSCatalogUpdate -Search $item.Title -Strict
    Save-MSCatalogUpdate -Update $updateObj -Destination $destDir -DownloadAll
}

### --- Push new files, then prune obsolete ones --- ###
if ($toDownload.Count -gt 0) {
    Push-Staging -LocalDir $stagingRoot
}
if ($toDelete.Count -gt 0) {
    Remove-RemoteFiles -RelativePaths ($toDelete | Select-Object -ExpandProperty RelativePath)
}

### --- Write and push updated manifest --- ###
$manifestPath = Join-Path $stagingRoot "manifest.json"
$desired | ConvertTo-Json -Depth 5 | Set-Content -Path $manifestPath
& rsync -avz -e ssh $manifestPath "${remote}:$repoPath/manifest.json"
if ($LASTEXITCODE -ne 0) { throw "rsync of manifest.json failed (exit $LASTEXITCODE)." }

Write-Host "Sync complete: $($toDownload.Count) downloaded, $($toDelete.Count) pruned, $($desired.Count - $toDownload.Count) unchanged."
