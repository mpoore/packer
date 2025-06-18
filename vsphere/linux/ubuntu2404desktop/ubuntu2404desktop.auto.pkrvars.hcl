# ----------------------------------------------------------------------------
# Name:         ubuntu2404desktop.auto.pkrvars.hcl
# Description:  Required vSphere variables for Ubuntu 24.04.LTS Packer builds
# Author:       Michael Poore (@mpoore)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

# ISO Settings
os_iso_file                     = "ubuntu-24.04.1-desktop-amd64.iso"
os_iso_path                     = "os/ubuntu/24"

# OS Meta Data
meta_os_family                  = "Linux"
meta_os_type                    = "Desktop"
meta_os_vendor                  = "Ubuntu"
meta_os_version                 = "24.04.1 LTS"

# VM Hardware Settings
vm_hardware_version             = 20
vm_firmware                     = "efi"
vm_cpu_sockets                  = 2
vm_cpu_cores                    = 1
vm_mem_size                     = 4096
vm_nic_type                     = "vmxnet3"
vm_disk_controller              = ["pvscsi"]
vm_disk_size                    = 131072
vm_disk_thin                    = true
vm_cdrom_type                   = "sata"

# VM Settings
vm_cdrom_remove                 = true
vcenter_convert_template        = false
vcenter_content_library_ovf     = true
vcenter_content_library_destroy = true

# VM OS Settings
build_guestos_type              = "ubuntu64Guest"
build_guestos_language          = "en_GB"
build_guestos_keyboard          = "gb"
build_guestos_timezone          = "UTC"
build_guestos_packages          = []

# Provisioner Settings
script_files                    = [ "scripts/linux/common/updates-apt.sh" ]
inline_cmds                     = []