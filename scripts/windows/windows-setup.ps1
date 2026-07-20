<#
    Basic configuration of vanilla Windows Server installation
    to progress Packer.io builds.

    - Switch network to Private (required for WinRM)
    - Install Windows Updates silently
    - Configure WinRM for remote management
    - Allow WinRM in Windows Firewall
    - Reset AutoLogonCount (known issue workaround)
    - Trigger single reboot at the end

    Name:         scripts/windows/windows-setup.ps1
    Author:       Michael Poore (@mpoore)
    URL:          https://github.com/mpoore/packer

#>

param(
    [string]$OfflineUpdateSource = '',
    [string]$SaltVersion = '',
    [switch]$SkipWindowsUpdate
)

$ErrorActionPreference = "Stop"

### --- Logging --- ###
$LogFile = "C:\Windows\Temp\packer-windows-setup.log"

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"

    Add-Content -Path $LogFile -Value $line

    switch ($Level) {
        "ERROR"   { Write-Host $line -ForegroundColor Red }
        "WARNING" { Write-Host $line -ForegroundColor Yellow }
        default   { Write-Host $line }
    }
}

function Write-LogException {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Context,

        [Parameter(Mandatory = $true)]
        $ErrorRecord
    )
    $position = ($ErrorRecord.InvocationInfo.PositionMessage -replace "`r?`n", " ").Trim()
    Write-Log -Level ERROR "$Context : $($ErrorRecord.Exception.Message) [$position]"
}

function Get-WindowsCodename {
    $build = [int](Get-CimInstance Win32_OperatingSystem).BuildNumber

    switch ($build) {
        { $_ -ge 26100 } { "win2025"; break }
        { $_ -ge 20348 } { "win2022"; break }
        { $_ -ge 17763 } { "win2019"; break }
        { $_ -ge 14393 } { "win2016"; break }
        default          { "unknown-$build" }
    }
}

function Wait-ForNetworkProfile {
    param(
        [int]$MaxAttempts = 18,
        [int]$DelaySeconds = 10
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            $profiles = @(Get-NetConnectionProfile -ErrorAction Stop)
        }
        catch {
            Write-LogException -Context "Get-NetConnectionProfile failed (attempt $attempt of $MaxAttempts)" -ErrorRecord $_
            Start-Sleep -Seconds $DelaySeconds
            continue
        }

        $identifying = $profiles | Where-Object { $_.Name -eq "Identifying..." }
        if (-not $identifying) {
            return $profiles
        }

        Write-Log "Network still identifying... waiting $DelaySeconds seconds. (attempt $attempt of $MaxAttempts)"
        Start-Sleep -Seconds $DelaySeconds
    }

    Write-Log -Level WARNING "Timed out after $MaxAttempts attempts waiting for network profile(s) to finish identifying. Proceeding with current state."
    try {
        return @(Get-NetConnectionProfile -ErrorAction Stop)
    }
    catch {
        Write-LogException -Context "Final Get-NetConnectionProfile attempt failed" -ErrorRecord $_
        return @()
    }
}

function Install-OfflineWindowsUpdates {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Product
    )

    $manifest = Invoke-RestMethod -Uri "$Source/manifest.json" -UseBasicParsing

    # Latest release per Kind only - the manifest can hold a retention
    # window of several months, we only want what's current.
    $entries = $manifest | Where-Object { $_.Product -eq $Product } |
        Group-Object Kind | ForEach-Object { $_.Group | Sort-Object LastUpdated -Descending | Select-Object -First 1 }

    # SSU before LCU, per Microsoft guidance.
    $ordered = $entries | Sort-Object { if ($_.Kind -eq 'Ssu') { 0 } else { 1 } }

    $downloadDir = "C:\Windows\Temp\winupdate-offline"
    New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null

    foreach ($entry in $ordered) {
        if (-not $entry.Files -or $entry.Files.Count -eq 0) {
            Write-Log -Level WARNING "No file list for $($entry.Kb) ($($entry.Kind)); skipping."
            continue
        }
        foreach ($file in $entry.Files) {
            $dest = Join-Path $downloadDir $file
            $uri = "$Source/$($entry.RelativePath)/$file"
            Write-Log "Downloading $($entry.Kb): $file ..."

            # Runs the download in a background job so the main thread can
            # poll the growing output file and log real progress - the
            # console-only progress bar Invoke-WebRequest shows by default
            # never reaches the log file anyway.
            $job = Start-Job -ScriptBlock {
                param($Uri, $Destination)
                Invoke-WebRequest -Uri $Uri -OutFile $Destination -UseBasicParsing
            } -ArgumentList $uri, $dest

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $lastLoggedMB = -1
            while ($job.State -eq 'Running') {
                Start-Sleep -Seconds 15
                if (Test-Path $dest) {
                    $currentMB = [math]::Round((Get-Item $dest).Length / 1MB, 1)
                    if ($currentMB -ne $lastLoggedMB) {
                        $lastLoggedMB = $currentMB
                        Write-Log "  ... $currentMB MB written ($([math]::Round($stopwatch.Elapsed.TotalSeconds))s elapsed)"
                    }
                }
            }
            $stopwatch.Stop()

            try {
                Receive-Job -Job $job -ErrorAction Stop | Out-Null
            }
            finally {
                Remove-Job -Job $job -Force
            }

            $sizeBytes = (Get-Item $dest).Length
            $sizeMB = [math]::Round($sizeBytes / 1MB, 2)
            $durationSeconds = $stopwatch.Elapsed.TotalSeconds
            if ($durationSeconds -gt 0) {
                $speedMbps = [math]::Round(($sizeBytes * 8) / ($durationSeconds * 1MB), 2)
                Write-Log "Downloaded $file: ${sizeMB} MB in $([math]::Round($durationSeconds, 1))s (${speedMbps} Mbps)"
            }
            else {
                Write-Log "Downloaded $file: ${sizeMB} MB"
            }

            Write-Log "Installing $file ..."
            $proc = Start-Process -FilePath "wusa.exe" -ArgumentList "`"$dest`" /quiet /norestart" -Wait -PassThru
            if ($proc.ExitCode -notin @(0, 3010)) {
                Write-Log -Level WARNING "wusa.exe exited $($proc.ExitCode) installing $file (may already be installed)."
            }
        }
    }
}

try {
    Write-Log "===== windows-setup.ps1 started ====="

    ### --- Network Configuration --- ###
    Write-Log "Configuring network profile..."
    try {
        $profiles = Wait-ForNetworkProfile

        if (-not $profiles) {
            Write-Log -Level WARNING "No network profiles were returned. Skipping network category change."
        }

        foreach ($netProfile in $profiles) {
            try {
                Set-NetConnectionProfile -InterfaceIndex $netProfile.InterfaceIndex -NetworkCategory Private -ErrorAction Stop
                Write-Log "Network profile '$($netProfile.Name)' (interface $($netProfile.InterfaceIndex)) set to Private."
            }
            catch {
                Write-LogException -Context "Failed to set network profile '$($netProfile.Name)' (interface $($netProfile.InterfaceIndex)) to Private" -ErrorRecord $_
            }
        }
    }
    catch {
        Write-LogException -Context "Network profile configuration failed. Continuing build..." -ErrorRecord $_
    }

    ### --- Windows Update --- ###
    if ($SkipWindowsUpdate) {
        Write-Log "Skipping Windows Update (SkipWindowsUpdate switch set)."
    }
    elseif ($OfflineUpdateSource) {
        Write-Log "Using offline Windows Update repository: $OfflineUpdateSource"
        try {
            $offlineUpdateProduct = Get-WindowsCodename
            Install-OfflineWindowsUpdates -Source $OfflineUpdateSource -Product $offlineUpdateProduct
            Write-Log "Offline Windows Updates installed. (Reboot will be forced at end of script)"
        }
        catch {
            Write-LogException -Context "Offline Windows Update failed. Continuing build..." -ErrorRecord $_
        }
    }
    else {
        Write-Log "Installing PSWindowsUpdate module..."
        try {
            Get-PackageProvider -Name nuget -Force | Out-Null
            Install-Module PSWindowsUpdate -Confirm:$false -Force
            Write-Log "Installing Windows Updates (online)..."
            Get-WindowsUpdate -MicrosoftUpdate -Install -IgnoreUserInput -AcceptAll -IgnoreReboot | Out-File -FilePath 'C:\windowsupdate.log' -Append
            Write-Log "Windows Updates installed. (Reboot will be forced at end of script)"
        }
        catch {
            Write-LogException -Context "Online Windows Update failed. Continuing build..." -ErrorRecord $_
        }
    }

    ### --- Salt Minion Installation --- ###
    $bootstrapUrl  = "https://raw.githubusercontent.com/saltstack/salt-bootstrap/develop/bootstrap-salt.ps1"
    $bootstrapPath = "C:\install\bootstrap-salt.ps1"
    $bootstrapArgs = "stable"

    try {
        if (-not (Test-Path -Path "C:\install")) {
            New-Item -Path "C:\install" -ItemType Directory -Force | Out-Null
        }

        try {
            Invoke-WebRequest -Uri $bootstrapUrl -OutFile $bootstrapPath -UseBasicParsing
            Write-Log "Downloaded bootstrap-salt.ps1 to $bootstrapPath"
        }
        catch {
            Write-LogException -Context "Failed to download bootstrap-salt.ps1" -ErrorRecord $_
            throw
        }

        try {
            Write-Log "Executing bootstrap-salt.ps1..."
            if ($SaltVersion) {
                Write-Log "Setting Salt version as: ${SaltVersion}"
                $bootstrapArgs += " ${SaltVersion}"
            }
            powershell.exe -ExecutionPolicy Bypass -File $bootstrapPath $bootstrapArgs
            if ($LASTEXITCODE -ne 0) {
                throw "bootstrap-salt.ps1 exited with code $LASTEXITCODE"
            }
            Write-Log "Salt bootstrap script completed."
        }
        catch {
            Write-LogException -Context "Failed to execute bootstrap-salt.ps1" -ErrorRecord $_
            throw
        }
    }
    catch {
        Write-Log -Level ERROR "===== setup.ps1 terminated: Salt Minion installation failed ====="
        exit 1
    }

    ### --- WinRM Configuration --- ###
    Write-Log "Configuring WinRM..."
    try {
        winrm quickconfig -quiet
        winrm set winrm/config/service '@{AllowUnencrypted="true"}'
        winrm set winrm/config/service/auth '@{Basic="true"}'
        Write-Log "WinRM configuration completed."
    }
    catch {
        Write-LogException -Context "WinRM configuration failed. Continuing build..." -ErrorRecord $_
    }

    ### --- Firewall Rules --- ###
    Write-Log "Enabling Windows Remote Management in Firewall..."
    try {
        netsh advfirewall firewall set rule group="Windows Remote Administration" new enable=yes
        netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new enable=yes action=allow
        Write-Log "Firewall rules applied."
    }
    catch {
        Write-LogException -Context "Failed to configure firewall rules. Continuing build..." -ErrorRecord $_
    }

    Write-Log "===== windows-setup.ps1 completed successfully ====="
}
catch {
    Write-LogException -Context "FATAL: unhandled error in windows-setup.ps1" -ErrorRecord $_
    Write-Log -Level ERROR "===== windows-setup.ps1 terminated with errors ====="
    exit 1
}