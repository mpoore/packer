# ----------------------------------------------------------------------------
# Name:         win2019.auto.pkrvars.hcl
# Description:  Required vSphere variables for Windows 2019 Packer builds
# Author:       Michael Poore (@mpoore)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

# ISO Settings
os_iso_file                     = "en-us_windows_server_2019_x64_dvd_f9475476.iso"
os_iso_path                     = "os/microsoft/server/2019"

# OS Meta Data
meta_os_family                  = "Windows"
meta_os_type                    = "Server"
meta_os_vendor                  = "Windows"
meta_os_version                 = "2019"

# VM Hardware Settings
vm_hardware_version             = 20
vm_firmware                     = "efi"
vm_cpu_sockets                  = 2
vm_cpu_cores                    = 1
vm_mem_size                     = 2048
vm_nic_type                     = "vmxnet3"
vm_disk_controller              = ["pvscsi"]
vm_disk_size                    = 51200
vm_disk_thin                    = true
vm_cdrom_type                   = "sata"

# VM Settings
vm_cdrom_remove                 = true
vcenter_convert_template        = false
vcenter_content_library_ovf     = true
vcenter_content_library_destroy = true

# VM OS Settings
build_guestos_type              = "windows2019srv_64Guest"
build_guestos_language          = "en-GB"
build_guestos_keyboard          = "en-GB"
build_guestos_systemlocale      = "en-US"
build_guestos_timezone          = "GMT Standard Time"

# Provisioner Settings
script_files                    = [ "scripts/windows/common/hibernation.ps1",
                                    "scripts/windows/common/administrator.ps1",
                                    "scripts/windows/common/tls.ps1",
                                    "scripts/windows/common/pki.ps1",
                                    "scripts/windows/common/cloud-init.ps1",
                                    "scripts/windows/common/rdp.ps1" ]
inline_cmds                     = [ "Get-EventLog -LogName * | ForEach { Clear-EventLog -LogName $_.Log }" ]