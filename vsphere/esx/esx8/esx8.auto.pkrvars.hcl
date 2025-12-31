# ----------------------------------------------------------------------------
# Name:         esx8.auto.pkrvars.hcl
# Description:  Required vSphere variables for ESXi 8 Packer builds
# Author:       Michael Poore (@mpoore)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

# ISO Settings
os_iso_file                     = "VMware-VMvisor-Installer-8.0U3b-24280767.x86_64.iso"
os_iso_path                     = "os/esx/8"

# OS Meta Data
meta_os_family                  = "ESX"
meta_os_type                    = "Hypervisor"
meta_os_vendor                  = "VMware"
meta_os_version                 = "8.0"
meta_os_subversion              = "u3b"

# VM Hardware Settings
vm_hardware_version             = 21
vm_firmware                     = "efi"
vm_cpu_sockets                  = 2
vm_cpu_cores                    = 1
vm_mem_size                     = 8192
vm_nic_type                     = "vmxnet3"
vm_disk_controller              = ["pvscsi"]
vm_disk_size                    = 65536
vm_disk_thin                    = true
vm_cdrom_type                   = "sata"

# VM Settings
vm_cdrom_remove                 = true
vcenter_convert_template        = false

# VM OS Settings
build_guestos_type              = "vmkernel8Guest"
build_guestos_language          = ""
build_guestos_keyboard          = "United Kingdom"
build_guestos_timezone          = ""

# Build Settings
build_ip_timeout                = "10m"
build_shutdown_timeout          = "1m"

# Provisioner Settings
script_files                    = []
inline_cmds                     = [ "chmod +x /etc/rc.local.d/local.sh",
                                    "sed -i 's#/system/uuid.*##' /etc/vmware/esx.conf",
                                    "/sbin/auto-backup.sh &> /dev/null" ]