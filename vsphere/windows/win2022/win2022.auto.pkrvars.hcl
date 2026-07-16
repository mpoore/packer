# ----------------------------------------------------------------------------
# Name:         win2022.auto.pkrvars.hcl
# Description:  Required vSphere variables for Windows 2022 Packer builds
# Author:       Michael Poore (@mpoore)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

# ISO Settings
os_iso_file                     = "en-us_windows_server_2022_updated_june_2026_x64_dvd_dda28eeb.iso"
os_iso_path                     = "os/microsoft/server/2022"

# OS Meta Data
meta_os_family                  = "Windows"
meta_os_type                    = "Server"
meta_os_vendor                  = "Microsoft"
meta_os_version                 = "2022"
meta_os_subversion              = "Std"

# VM Hardware Settings
vm_hardware_version             = 22
vm_firmware                     = "efi"
vm_cpu_sockets                  = 2
vm_cpu_cores                    = 1
vm_mem_size                     = 4096
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
build_guestos_type              = "windows2019srvNext_64Guest"
build_guestos_language          = "en-GB"
build_guestos_keyboard          = "en-GB"
build_guestos_systemlocale      = "en-US"
build_guestos_timezone          = "GMT Standard Time"

# Timeout Settings
build_ip_timeout                = "100m"
build_winrm_timeout             = "120m"
build_shutdown_timeout          = "120m"

# Provisioner Settings
state_tree                      = "salt/states/windows"
pillar_tree                     = "salt/pillars"