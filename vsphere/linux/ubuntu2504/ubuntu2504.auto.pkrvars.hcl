# ----------------------------------------------------------------------------
# Name:         ubuntu2504.auto.pkrvars.hcl
# Description:  Required vSphere variables for Ubuntu 25.04 Packer builds
# Author:       Michael Poore (@mpoore)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

# ISO Settings
os_iso_file                     = "ubuntu-25.04-live-server-amd64.iso"
os_iso_path                     = "os/ubuntu/25"

# OS Meta Data
meta_os_family                  = "Linux"
meta_os_type                    = "Server"
meta_os_vendor                  = "Ubuntu"
meta_os_version                 = "25.04"

# VM Hardware Settings
vm_hardware_version             = 21
vm_firmware                     = "efi"
vm_cpu_sockets                  = 1
vm_cpu_cores                    = 1
vm_mem_size                     = 2048
vm_nic_type                     = "vmxnet3"
vm_disk_controller              = ["pvscsi"]
vm_disk_size                    = 32768
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
state_tree                      = "salt/states"
pillar_tree                     = "salt/pillars"