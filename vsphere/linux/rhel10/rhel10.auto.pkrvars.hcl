# ----------------------------------------------------------------------------
# Name:         rhel10.auto.pkrvars.hcl
# Description:  Required vSphere variables for RedHat 10 Packer builds
# Author:       Michael Poore (@mpoore)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

# ISO Settings
os_iso_file                     = "rhel-10.2-x86_64-dvd.iso"
os_iso_path                     = "os/redhat/10"

# OS Meta Data
meta_os_family                  = "Linux"
meta_os_type                    = "Server"
meta_os_vendor                  = "RedHat"
meta_os_version                 = "10.2"

# VM Hardware Settings
vm_hardware_version             = 22
vm_firmware                     = "efi"
vm_cpu_sockets                  = 1
vm_cpu_cores                    = 1
vm_mem_size                     = 2048
vm_nic_type                     = "vmxnet3"
vm_disk_controller              = ["pvscsi"]
vm_disk_size                    = 65536
vm_disk_thin                    = true
vm_cdrom_type                   = "sata"

# VM Settings
vm_cdrom_remove                 = true
vcenter_convert_template        = false
vcenter_content_library_ovf     = true
vcenter_content_library_destroy = true

# VM OS Settings
build_guestos_type              = "rhel10_64Guest"
build_guestos_language          = "en_GB"
build_guestos_keyboard          = "gb"
build_guestos_timezone          = "UTC"
build_guestos_packages          = [ "openssl", "salt-3006.23", "salt-minion-3006.23" ]

# Timeout Settings
build_ip_timeout                = "30m"
build_ssh_timeout               = "5m"
build_shutdown_timeout          = "5m"

# Provisioner Settings
state_tree                      = "salt/states/linux"
pillar_tree                     = "salt/pillars/linux"