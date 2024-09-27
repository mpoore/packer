# Disable password expiration for Administrator
# @author Michael Poore
$ErrorActionPreference = "Stop"

# Disable password expiration for Administrator
Write-Host "-- Disabling password expiration for local Administrator user ..."
Set-LocalUser Administrator -PasswordNeverExpires $true