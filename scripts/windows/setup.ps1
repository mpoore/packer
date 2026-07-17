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
    <#Write-Log "Installing PSWindowsUpdate module..."
    Get-PackageProvider -Name nuget -Force | Out-Null
    Install-Module PSWindowsUpdate -Confirm:$false -Force

    Write-Log "Installing Windows Updates..."
    Get-WindowsUpdate -MicrosoftUpdate -Install -IgnoreUserInput -AcceptAll -IgnoreReboot | Out-File -FilePath 'C:\windowsupdate.log' -Append
    Write-Log "Windows Updates installed. (Reboot will be forced at end of script)"#>

    ### --- Salt Minion Installation --- ###
    $bootstrapUrl  = "https://raw.githubusercontent.com/saltstack/salt-bootstrap/develop/bootstrap-salt.ps1"
    $bootstrapPath = "C:\install\bootstrap-salt.ps1"

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
            powershell.exe -ExecutionPolicy Bypass -File $bootstrapPath
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