# ----------------------------------------------------------------------------
# Name:         photon4.auto.pkrvars.hcl
# Description:  Required vSphere variables for Photon 4 Packer builds
# Author:       Michael Poore (@mpoore)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

# ISO Settings
os_iso_file                     = "photon-4.0-c001795b8.iso"
os_iso_path                     = "os/photon/4"

# OS Meta Data
meta_os_family                  = "Linux"
meta_os_type                    = "Server"
meta_os_vendor                  = "Photon"
meta_os_version                 = "4.0"

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
build_guestos_type              = "vmwarePhoton64Guest"
build_guestos_language          = "en_GB"
build_guestos_keyboard          = "gb"
build_guestos_timezone          = "UTC"
build_guestos_packages          = [ "curl", "git", "net-tools", "salt-minion", "unzip", "vim", "wget" ]

# Provisioner Settings
state_tree                      = "salt/states"
pillar_tree                     = "salt/pillars"