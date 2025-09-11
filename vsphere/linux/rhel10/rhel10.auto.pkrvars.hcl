# ----------------------------------------------------------------------------
# Name:         rhel10.auto.pkrvars.hcl
# Description:  Required vSphere variables for RedHat 10 Packer builds
# Author:       Michael Poore (@mpoore)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

# ISO Settings
os_iso_file                     = "rhel-10.0-x86_64-dvd.iso"
os_iso_path                     = "os/redhat/10"

# OS Meta Data
meta_os_family                  = "Linux"
meta_os_type                    = "Server"
meta_os_vendor                  = "RedHat"
meta_os_version                 = "10.0"

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
build_guestos_type              = "other5xLinux64Guest"
build_guestos_language          = "en_GB"
build_guestos_keyboard          = "gb"
build_guestos_timezone          = "UTC"
build_guestos_packages          = [ "salt-minion" ]

# Provisioner Settings
state_tree                      = "salt/states"
pillar_tree                     = "salt/pillars"