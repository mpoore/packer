# ----------------------------------------------------------------------------
# Name:         vars.pkr.hcl
# Description:  Variable definitions for vSphere Packer builds
# Author:       Michael Poore (@mpoore)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

# -------------------------------------------------------------------------- #
#                           Variable Definitions                             #
# -------------------------------------------------------------------------- #
# Contents:
#       1. Sensitive Variables
#       2. VMware vCenter Configuration
#       3. VMware Virtual Machine (VM) Hardware Settings
#       4. VMware vSphere Content Library and Template Configuration
#       5. OS ISO Configuration
#       6. OS Customisation and Region Settings
#       7. OS Meta Data
#       8. Build Timeout Settings
#       9. Packer Provisioner Settings
#      10. Common Build Variables

# -------------------------------------------------------------------------- #
# 1. Sensitive Variables
#       Used for usernames and passwords to connect to providers or configure
#       within builds.
#
variable "vcenter_username" {
    type        = string
    description = "Username used by Packer to connect to vCenter"
    sensitive   = true
    default     = "administrator@vsphere.local"
}
variable "vcenter_password" {
    type        = string
    description = "Password used by Packer to connect to vCenter"
    sensitive   = true
    default     = ""
}
variable "admin_username" {
    type        = string
    description = "Default administrative username for the build OS"
    sensitive   = true
    default     = "administrator"
}
variable "admin_password" {
    type        = string
    description = "Password for the default administrative user"
    sensitive   = true
    default     = ""
}
variable "build_username" {
    type        = string
    description = "Non-administrative username for the build OS"
    sensitive   = true
    default     = "build"
}
variable "build_password" {
    type        = string
    description = "Password for the non-administrative user"
    sensitive   = true
    default     = ""
}
variable "build_password_encrypted" {
    type        = string
    description = "Encrypted password for the non-administrative user"
    sensitive   = true
    default     = ""
}
variable "build_configmgmt_user" {
    type        = string
    description = "Name of the user to be used by Configuration Management tooling"
    sensitive   = true
    default     = ""
}
variable "build_configmgmt_key" {
    type        = string
    description = "SSH key for the Configuration Management tooling user"
    sensitive   = true
    default     = ""
}
variable "rhsm_user" {
    type        = string
    description = "RedHat Subscription Manager username"
    sensitive   = true
    default     = ""
}
variable "rhsm_pass" {
    type        = string
    description = "RedHat Subscription Manager password"
    sensitive   = true
    default     = ""
}

# -------------------------------------------------------------------------- #
# 2. VMware vCenter Configuration
#       Connection and build target configuration for VMware vCenter builds.
#
variable "vcenter_server" {
    type        = string
    description = "FQDN for the vCenter Server Packer will create this build in"
    default     = ""
}
variable "vcenter_insecure" {
    type        = bool
    description = "Validate the SSL connection to vCenter"
    default     = true
}
variable "vcenter_datacenter" {
    type        = string
    description = "Datacenter name in vCenter where the build will be created"
    default     = ""
}
variable "vcenter_cluster" {
    type        = string
    description = "Cluster name in vCenter where the build will be created"
    default     = ""
}
variable "vcenter_folder" {
    type        = string
    description = "Folder path in vCenter where the build will be created"
    default     = ""
}
variable "vcenter_datastore" {
    type        = string
    description = "vSphere datastore where the build will be created"
    default     = ""
}
variable "vcenter_network" {
    type        = string
    description = "vSphere network where the build will be created"
    default     = ""
}

# -------------------------------------------------------------------------- #
# 3. VMware Virtual Machine (VM) Hardware Settings
#       Defines the VM hardware settings used to create a build in vCenter.
#
variable "vm_firmware" {
    type        = string
    description = "Type of VM firmware to use (one of 'efi', 'efi-secure' or 'bios')"
    default     = "efi-secure"
}
variable "vm_hardware_version" {
    type        = number
    description = "Version of VM hardware to use (e.g. '18' or '19' etc)"
    default     = 19
}
variable "vm_boot_order" {
    type        = string
    description = "Set the comma-separated boot order for the VM (e.g. 'disk,cdrom')"
    default     = "disk,cdrom"
}
variable "vm_boot_wait" {
    type        = string
    description = "Set the delay for the VM to wait after booting before the boot command is sent (e.g. '1h5m2s' or '2s')"
    default     = "2s"
}
variable "vm_tools_policy" {
    type        = bool
    description = "Upgrade VM tools on reboot?"
    default     = true
}
variable "vm_cpu_sockets" {
    type        = number
    description = "The number of CPU sockets for the VM"
    default     = 1
}
variable "vm_cpu_cores" {
    type        = number
    description = "The number of cores per CPU socket for the VM"
    default     = 1
}
variable "vm_cpu_hotadd" {
    type        = bool
    description = "Enable CPU hot-add"
    default     = false
}
variable "vm_mem_size" {
    type        = number
    description = "The size of memory in MB for the VM"
    default     = 2048
}
variable "vm_mem_hotadd" {
    type        = bool
    description = "Enable Memory hot-add"
    default     = false
}
variable "vm_cdrom_type" {
    type        = string
    description = "Type of CD-ROM drive to add to the VM (e.g. 'sata' or 'ide')"
    default     = "sata"
}
variable "vm_cdrom_remove" {
    type        = bool
    description = "Remove CD-ROM drives when provisioning is complete?"
    default     = true
}
variable "vm_nic_type" {
    type        = string
    description = "Type of network card for the VM (e.g. 'e1000e' or 'vmxnet3')"
    default     = "vmxnet3"
}
variable "vm_disk_controller" {
    type        = list(string)
    description = "An ordered list of disk controller types to be added to the VM (e.g. one of more of 'pvscsi', 'scsi' etc)"
    default     = ["pvscsi"]
}
variable "vm_disk_size" {
    type        = number
    description = "The size of system disk in MB for the VM"
    default     = 40960
}
variable "vm_disk_thin" {
    type        = bool
    description = "Thin provision the disk?"
    default     = true
}
variable "vcenter_iso_datastore" {
    type        = string
    description = "vSphere datastore name where source OS media reside"
    default     = ""
}

# -------------------------------------------------------------------------- #
# 4. VMware vSphere Content Library and Template Configuration
#       Configuration for the creation and handling of vCenter templates
#       and the vSphere COntent Library.
#
variable "vcenter_convert_template" {
    type        = bool
    description = "Convert the VM to a template?"
    default     = false
}
variable "vcenter_content_library" {
    type        = string
    description = "Name of the vSphere Content Library to export the VM to"
    default     = ""
}
variable "vcenter_content_library_ovf" {
    type        = bool
    description = "Export to Content Library as an OVF file?"
    default     = true
}
variable "vcenter_content_library_destroy" {
    type        = bool
    description = "Delete the VM after successfully exporting to a Content Library?"
    default     = true
}
variable "vcenter_content_library_skip" {
    type        = bool
    description = "Skip adding the VM to a Content Library?"
    default     = false
}
variable "vcenter_snapshot" {
    type        = bool
    description = "Create a snapshot of the VM?"
    default     = false
}
variable "vcenter_snapshot_name" {
    type        = string
    description = "Name of the snapshot to be created on the VM"
    default     = "Created by Packer"
}

# -------------------------------------------------------------------------- #
# 5. OS ISO Configuration
#       Defines how source media for the build is accessed.
#
variable "os_iso_path" {
    type        = string
    description = "Path to the OS media"
    default     = ""
}
variable "os_iso_file" {
    type        = string
    description = "OS media file name"
    default     = ""
}

# -------------------------------------------------------------------------- #
# 6. OS Customisation and Region Settings
#       Region and keyboard settings for the build OS.
#
variable "build_guestos_type" {
    type        = string
    description = "The type of guest operating system (or guestid) in vSphere"
    default     = "rhel9_64Guest"
}
variable "build_guestos_language" {
    type        = string
    description = "The language that the guest OS will be configured with"
    default     = "en-GB"
}
variable "build_guestos_keyboard" {
    type        = string
    description = "The keyboard type that the guest OS will use"
    default     = "en-GB"
}
variable "build_guestos_timezone" {
    type        = string
    description = "The timezone the guest OS will be set to"
    default     = "GMT Standard Time"
}
variable "build_guestos_systemlocale" {
    type        = string
    description = "The language that the guest OS will be configured with"
    default     = "en-US"
}

# -------------------------------------------------------------------------- #
# 7. OS Meta Data
#       Meta data about the OS installed in the build.
#
variable "meta_os_family" {
    type        = string
    description = "The family that the OS belongs to (e.g. 'Windows' or 'Linux')"
    default     = "Linux"
}
variable "meta_os_vendor" {
    type        = string
    description = "The vendor or product name for the OS (e.g. 'Photon', 'RHEL', 'CentOS, 'Ubuntu', 'Windows' etc)"
    default     = "RHEL"
}
variable "meta_os_type" {
    type        = string
    description = "The type of OS (e.g. 'Server' or 'Desktop')"
    default     = "Server"
}
variable "meta_os_version" {
    type        = string
    description = "The major version of the OS (e.g. '7', '8.5', '2022')"
    default     = "9"
}

# -------------------------------------------------------------------------- #
# 8. Build Timeout Settings
#       Packer build timeout settings.
#
variable "build_ip_timeout" {
    type        = string
    description = "Set the timeout for the build to obtain an IP address (e.g. '1h5m2s' or '2s')"
    default     = "30m"
}
variable "build_shutdown_timeout" {
    type = string
    description = "Set the timeout for the build to shutdown after the shutdown command is issued (e.g. '1h5m2s' or '2s')"
    default     = "30m"
}

# -------------------------------------------------------------------------- #
# 9. Packer Provisioner Settings
#       Common settings for Packer Provisioners.
#
variable "script_files" {
    type        = list(string)
    description = "List of OS scripts to execute"
    default     = []
}
variable "inline_cmds" {
    type        = list(string)
    description = "List of OS commands to execute"
    default     = []
}
variable "root_pem_files" {
    type        = string
    description = "Comma separated list of absolute URLs to root PEM certificates"
    default     = ""
}
variable "issuing_pem_files" {
    type        = string
    description = "Comma separated list of absolute URLs to issuing PEM certificates"
    default     = ""
}

# -------------------------------------------------------------------------- #
# 10. Common Build Variables
#       Misc build variables.
#
variable "build_repo" {
    type        = string
    description = "Source control respository this build comes from"
    default     = "https://github.com/mpoore/packer"
}
variable "build_pkiserver" {
    type        = string
    description = "Base URL for acquiring SSL certificates"
    default     = ""
}