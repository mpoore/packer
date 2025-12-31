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
#>

$ErrorActionPreference = "Stop"

### --- Network Configuration --- ###
Write-Host "Configuring network profile..."
$profile = Get-NetConnectionProfile
while ($profile.Name -eq "Identifying...") {
    Write-Host "Network still identifying... waiting 10 seconds."
    Start-Sleep -Seconds 10
    $profile = Get-NetConnectionProfile
}
Set-NetConnectionProfile -Name $profile.Name -NetworkCategory Private
Write-Host "Network profile set to Private."

### --- Windows Update --- ###
Write-Host "Installing PSWindowsUpdate module..."
Get-PackageProvider -Name nuget -Force | Out-Null
Install-Module PSWindowsUpdate -Confirm:$false -Force

Write-Host "Installing Windows Updates..."
Get-WindowsUpdate -MicrosoftUpdate -Install -IgnoreUserInput -AcceptAll -IgnoreReboot | Out-File -FilePath 'C:\windowsupdate.log' -Append
Write-Host "Windows Updates installed. (Reboot will be forced at end of script)"

### --- VMware Tools Installation --- ###
$vmwareToolsPath = "E:\setup.exe"
if (Test-Path $vmwareToolsPath) {
    Write-Host "Installing VMware Tools from $vmwareToolsPath ..."
    try {
        Start-Process -FilePath $vmwareToolsPath `
            -ArgumentList '/S /v"/qn REBOOT=ReallySuppress" /l c:\windows\temp\vmware_tools_install.log' `
            -Wait -NoNewWindow
        Write-Host "VMware Tools installation completed."
    }
    catch {
        Write-Warning "VMware Tools installation failed: $_. Continuing build..."
    }
}
else {
    Write-Warning "VMware Tools installer not found at $vmwareToolsPath. Skipping installation."
}

### --- Salt Minion Installation --- ###
$bootstrapUrl  = "https://raw.githubusercontent.com/saltstack/salt-bootstrap/develop/bootstrap-salt.ps1"
$bootstrapPath = "C:\install\bootstrap-salt.ps1"

if (-not (Test-Path -Path "C:\install")) {
    New-Item -Path "C:\install" -ItemType Directory -Force | Out-Null
}

try {
    Invoke-WebRequest -Uri $bootstrapUrl -OutFile $bootstrapPath -UseBasicParsing
    Write-Host "Downloaded bootstrap-salt.ps1 to $bootstrapPath"
}
catch {
    Write-Error "Failed to download bootstrap-salt.ps1: $_"
    exit 1
}

try {
    Write-Host "Executing bootstrap-salt.ps1..."
    powershell.exe -ExecutionPolicy Bypass -File $bootstrapPath
    Write-Host "Salt bootstrap script completed."
}
catch {
    Write-Error "Failed to execute bootstrap-salt.ps1: $_"
    exit 1
}

### --- OpenSSH Configuration --- ####
#Write-Host "Configuring OpenSSH..."
# Check if OpenSSH Server is installed
#$sshCapability = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
#if ($sshCapability.State -ne 'Installed') {
#    Write-Host "Installing OpenSSH Server..."
#    Add-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0'
#} else {
#    Write-Host "OpenSSH Server already installed."
#}

# Check if the OpenSSH service is running
#$sshService = Get-Service -Name sshd -ErrorAction SilentlyContinue
#if ($sshService -eq $null) {
#    Write-Host "sshd service not found, something went wrong."
#} elseif ($sshService.Status -ne 'Running') {
#    Write-Host "Starting sshd service..."
#    Start-Service sshd
#} else {
#    Write-Host "sshd service already running."
#}

# Open port 22 in Windows Firewall
#Write-Host "Adding firewall rule to allow port 22..."
#New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' `
#                    -DisplayName 'OpenSSH-Server-In-TCP' `
#                    -Enabled True `
#                    -Direction Inbound `
#                    -Protocol TCP `
#                    -LocalPort 22 `
#                    -Action Allow

### --- WinRM Configuration --- ###
Write-Host "Configuring WinRM..."
try {
    winrm quickconfig -quiet
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm set winrm/config/service/auth '@{Basic="true"}'
    Write-Host "WinRM configuration completed."
}
catch {
    Write-Warning "WinRM configuration failed: $_. Continuing build..."
}

### --- Firewall Rules --- ###
Write-Host "Enabling Windows Remote Management in Firewall..."
try {
    netsh advfirewall firewall set rule group="Windows Remote Administration" new enable=yes
    netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new enable=yes action=allow
    Write-Host "Firewall rules applied."
}
catch {
    Write-Warning "Failed to configure firewall rules: $_. Continuing build..."
}