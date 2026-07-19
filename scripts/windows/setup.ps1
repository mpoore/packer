<#
    Basic configuration of vanilla Windows Server installation
    to progress Packer.io builds.

    - Switch network to Private (required for WinRM)
    - Install Windows Updates silently
    - Install VMware Tools from E:\setup.exe (if available)
    - Configure WinRM for remote management
    - Allow WinRM in Windows Firewall
    - Reset AutoLogonCount (known issue workaround)
    - Trigger single reboot at the end

    Name:         scripts/windows/setup.ps1
    Author:       Michael Poore (@mpoore)
    URL:          https://github.com/mpoore/packer

    Log:          C:\Windows\Temp\packer-setup.log
#>

param(
    [string]$OfflineUpdateSource = '',
    [string]$OfflineUpdateProduct = '',
    [string]$SaltVersion = '',
    [switch]$SkipWindowsUpdate
)

$ErrorActionPreference = "Stop"

### --- Logging --- ###
$LogFile = "C:\Windows\Temp\packer-setup.log"

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
    Write-Log "===== setup.ps1 started ====="

    ### --- VMware Tools Installation --- ###
    $vmwareToolsPath = "E:\setup.exe"
    if (Test-Path $vmwareToolsPath) {
        Write-Log "Installing VMware Tools from $vmwareToolsPath ..."
        try {
            Start-Process -FilePath $vmwareToolsPath `
                -ArgumentList '/S /v"/qn REBOOT=ReallySuppress" /l c:\windows\temp\vmware_tools_install.log' `
                -Wait -NoNewWindow
            Write-Log "VMware Tools installation completed."
        }
        catch {
            Write-LogException -Context "VMware Tools installation failed. Continuing build..." -ErrorRecord $_
        }
    }
    else {
        Write-Log -Level WARNING "VMware Tools installer not found at $vmwareToolsPath. Skipping installation."
    }

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
            Install-OfflineWindowsUpdates -Source $OfflineUpdateSource -Product $OfflineUpdateProduct
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

    ### --- OpenSSH Configuration --- ####
    #Write-Log "Configuring OpenSSH..."
    # Check if OpenSSH Server is installed
    #$sshCapability = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
    #if ($sshCapability.State -ne 'Installed') {
    #    Write-Log "Installing OpenSSH Server..."
    #    Add-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0'
    #} else {
    #    Write-Log "OpenSSH Server already installed."
    #}

    # Check if the OpenSSH service is running
    #$sshService = Get-Service -Name sshd -ErrorAction SilentlyContinue
    #if ($sshService -eq $null) {
    #    Write-Log "sshd service not found, something went wrong."
    #} elseif ($sshService.Status -ne 'Running') {
    #    Write-Log "Starting sshd service..."
    #    Start-Service sshd
    #} else {
    #    Write-Log "sshd service already running."
    #}

    # Open port 22 in Windows Firewall
    #Write-Log "Adding firewall rule to allow port 22..."
    #New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' `
    #                    -DisplayName 'OpenSSH-Server-In-TCP' `
    #                    -Enabled True `
    #                    -Direction Inbound `
    #                    -Protocol TCP `
    #                    -LocalPort 22 `
    #                    -Action Allow

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

    Write-Log "===== setup.ps1 completed successfully ====="
}
catch {
    Write-LogException -Context "FATAL: unhandled error in setup.ps1" -ErrorRecord $_
    Write-Log -Level ERROR "===== setup.ps1 terminated with errors ====="
    exit 1
}