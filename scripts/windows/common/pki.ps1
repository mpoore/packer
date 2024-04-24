# Import trusted CA certs
# @author Michael Poore
$ErrorActionPreference = "Stop"

Function Import-Certs($certlist,$certtype) {
  $certs = $certlist.Split(",")
  For ($i = 0; $i -lt $certs.Length; $i++) {
    $cert = $certs[$i]
    Write-Host "  -- Downloading $cert"
    Invoke-WebRequest -Uri ($cert) -OutFile C:\certificate.crt
    Switch ($certtype)
      {
        "root" {
          Write-Host "  -- Importing root certificate"
          Import-Certificate -FilePath C:\certificate.crt -CertStoreLocation 'Cert:\LocalMachine\Root' | Out-Null
        }
        "issuing" {
          Write-Host "  -- Importing issuing certificate"
          Import-Certificate -FilePath C:\certificate.crt -CertStoreLocation 'Cert:\LocalMachine\CA' | Out-Null
        }
      }
    Remove-Item C:\certificate.crt -Confirm:$false
  }
}

# Importing trusted CA certificates
Write-Host "-- Importing trusted CA certificates ..."
If (![string]::IsNullOrEmpty($env:ROOTPEMFILES)) {
  Import-Certs $env:ROOTPEMFILES "root"
}
If (![string]::IsNullOrEmpty($env:ISSUINGPEMFILES)) {
  Import-Certs $env:ISSUINGPEMFILES "issuing"
}