<#
    Installation of VMware Tools package to progress Packer.io builds.

    - Install VMware Tools from E:\setup.exe (if available)

    Name:         scripts/windows/install-vmtools.ps1
    Author:       Michael Poore (@mpoore)
    URL:          https://github.com/mpoore/packer

#>

$ErrorActionPreference = "SilentlyContinue"

### --- Logging --- ###
$LogFile = "C:\Windows\Temp\packer-install-vmtools.log"

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

try {
    Write-Log "===== install-vmtools.ps1 started ====="

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

    Write-Log "===== install-vmtools.ps1 completed successfully ====="
}
catch {
    Write-LogException -Context "FATAL: unhandled error in install-vmtools.ps1" -ErrorRecord $_
    Write-Log -Level ERROR "===== install-vmtools.ps1 terminated with errors ====="
    exit 1
}