# ----------------------------------------------------------------------------
# Name:         centos9.auto.pkrvars.hcl
# Description:  Required vSphere variables for CentOS 9 Packer builds
# Author:       Michael Poore (@mpoore)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

# ISO Settings
os_iso_file                     = "CentOS-Stream-9-latest-x86_64-dvd1.iso"
os_iso_path                     = "os/centos/9"

# OS Meta Data
meta_os_family                  = "Linux"
meta_os_type                    = "Server"
meta_os_vendor                  = "CentOS"
meta_os_version                 = "9"

# VM Hardware Settings
vm_hardware_version             = 20
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
build_guestos_type              = "centos9_64Guest"
build_guestos_language          = "en_GB"
build_guestos_keyboard          = "gb"
build_guestos_timezone          = "UTC"
build_additional_packages       = [ "curl", "git",
                                    "net-tools", "ntp", "ntpdate",
                                    "unzip", "vim", "wget" ]

# Provisioner Settings
script_files                    = [ "scripts/linux/common/updates-dnf.sh",
                                    "scripts/linux/common/sshd.sh",
                                    "scripts/linux/rhel/pki.sh",
                                    "scripts/linux/rhel/hashicorp.sh",
                                    "scripts/linux/rhel/salt-minion.sh",
                                    "scripts/linux/common/motd.sh",
                                    "scripts/linux/rhel/cleanup.sh" ]
inline_cmds                     = []