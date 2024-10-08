# ----------------------------------------------------------------------------
# Name:         win2019.pkr.hcl
# Description:  Build definition for Windows 2019
# Author:       Michael Poore (@mpoore)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

# -------------------------------------------------------------------------- #
#                           Packer Configuration                             #
# -------------------------------------------------------------------------- #
packer {
    required_version = ">= 1.11.2"
    required_plugins {
        vsphere = {
            version = ">= 1.4.0"
            source  = "github.com/hashicorp/vsphere"
        }
        windows-update = {
            version = ">= 0.16.8"
            source  = "github.com/rgl/windows-update"
        }
    }
}

# -------------------------------------------------------------------------- #
#                              Local Variables                               #
# -------------------------------------------------------------------------- #
locals { 
    build_version               = formatdate("YY.MM (DD.hhmm)", timestamp())
    build_date                  = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
    core_floppy_content         = {
                                    "Autounattend.xml" = templatefile("${abspath(path.root)}/cfg/Autounattend.pkrtpl.hcl", {
                                        admin_password              = var.admin_password
                                        build_guestos_language      = var.build_guestos_language
                                        build_guestos_systemlocale  = var.build_guestos_systemlocale
                                        build_guestos_keyboard      = var.build_guestos_keyboard
                                        build_guestos_timezone      = var.build_guestos_timezone
                                        build_windows_image         = "SERVERSTANDARDCORE"
                                    })
                                  }
    dexp_floppy_content         = {
                                    "Autounattend.xml" = templatefile("${abspath(path.root)}/cfg/Autounattend.pkrtpl.hcl", {
                                        admin_password              = var.admin_password
                                        build_guestos_language      = var.build_guestos_language
                                        build_guestos_systemlocale  = var.build_guestos_systemlocale
                                        build_guestos_keyboard      = var.build_guestos_keyboard
                                        build_guestos_timezone      = var.build_guestos_timezone
                                        build_windows_image         = "SERVERSTANDARD"
                                    })
                                  }
    vm_description              = "VER: ${ local.build_version }\nISO: ${ var.os_iso_file }"
}

# -------------------------------------------------------------------------- #
#                       Template Source Definitions                          #
# -------------------------------------------------------------------------- #
source "vsphere-iso" "win2019stddexp" {
    # vCenter
    vcenter_server              = var.vcenter_server
    username                    = var.vcenter_username
    password                    = var.vcenter_password
    insecure_connection         = var.vcenter_insecure
    datacenter                  = var.vcenter_datacenter
    cluster                     = var.vcenter_cluster
    folder                      = var.vcenter_folder
    datastore                   = var.vcenter_datastore

    # Content Library and Template Settings
    convert_to_template         = var.vcenter_convert_template
    create_snapshot             = var.vcenter_snapshot
    snapshot_name               = var.vcenter_snapshot_name
    dynamic "content_library_destination" {
        for_each = var.vcenter_content_library != null ? [1] : []
            content {
                library         = var.vcenter_content_library
                name            = "${ source.name }"
                description     = local.vm_description
                ovf             = var.vcenter_content_library_ovf
                destroy         = var.vcenter_content_library_destroy
                skip_import     = var.vcenter_content_library_skip
            }
    }

    # Virtual Machine
    guest_os_type               = var.build_guestos_type
    vm_name                     = "${ source.name }"
    notes                       = local.vm_description
    firmware                    = var.vm_firmware
    CPUs                        = var.vm_cpu_sockets
    cpu_cores                   = var.vm_cpu_cores
    CPU_hot_plug                = var.vm_cpu_hotadd
    RAM                         = var.vm_mem_size
    RAM_hot_plug                = var.vm_mem_hotadd
    cdrom_type                  = var.vm_cdrom_type
    remove_cdrom                = var.vm_cdrom_remove
    disk_controller_type        = var.vm_disk_controller
    storage {
        disk_size               = var.vm_disk_size
        disk_thin_provisioned   = var.vm_disk_thin
    }
    network_adapters {
        network                 = var.vcenter_network
        network_card            = var.vm_nic_type
    }

    # Removeable Media
    iso_paths                   = [ "[${ var.vcenter_iso_datastore }] ${ var.os_iso_path }/${ var.os_iso_file }", "[] /vmimages/tools-isoimages/windows.iso" ]
    floppy_files                = [ "scripts/windows/common/initialise.ps1" ]
    floppy_content              = local.dexp_floppy_content

    # Boot and Provisioner
    boot_order                  = var.vm_boot_order
    boot_wait                   = var.vm_boot_wait
    boot_command                = [ "<spacebar>" ]
    ip_wait_timeout             = var.build_ip_timeout
    communicator                = "winrm"
    winrm_username              = var.admin_username
    winrm_password              = var.admin_password
    shutdown_command            = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Complete\""
    shutdown_timeout            = var.build_shutdown_timeout
}

source "vsphere-iso" "win2019stdcore" {
    # vCenter
    vcenter_server              = var.vcenter_server
    username                    = var.vcenter_username
    password                    = var.vcenter_password
    insecure_connection         = var.vcenter_insecure
    datacenter                  = var.vcenter_datacenter
    cluster                     = var.vcenter_cluster
    folder                      = var.vcenter_folder
    datastore                   = var.vcenter_datastore

    # Content Library and Template Settings
    convert_to_template         = var.vcenter_convert_template
    create_snapshot             = var.vcenter_snapshot
    snapshot_name               = var.vcenter_snapshot_name
    dynamic "content_library_destination" {
        for_each = var.vcenter_content_library != null ? [1] : []
            content {
                library         = var.vcenter_content_library
                name            = "${ source.name }"
                description     = local.vm_description
                ovf             = var.vcenter_content_library_ovf
                destroy         = var.vcenter_content_library_destroy
                skip_import     = var.vcenter_content_library_skip
            }
    }

    # Virtual Machine
    guest_os_type               = var.build_guestos_type
    vm_name                     = "${ source.name }"
    notes                       = local.vm_description
    firmware                    = var.vm_firmware
    CPUs                        = var.vm_cpu_sockets
    cpu_cores                   = var.vm_cpu_cores
    CPU_hot_plug                = var.vm_cpu_hotadd
    RAM                         = var.vm_mem_size
    RAM_hot_plug                = var.vm_mem_hotadd
    cdrom_type                  = var.vm_cdrom_type
    remove_cdrom                = var.vm_cdrom_remove
    disk_controller_type        = var.vm_disk_controller
    storage {
        disk_size               = var.vm_disk_size
        disk_thin_provisioned   = var.vm_disk_thin
    }
    network_adapters {
        network                 = var.vcenter_network
        network_card            = var.vm_nic_type
    }

    # Removeable Media
    iso_paths                   = [ "[${ var.vcenter_iso_datastore }] ${ var.os_iso_path }/${ var.os_iso_file }", "[] /vmimages/tools-isoimages/windows.iso" ]
    floppy_files                = [ "scripts/windows/common/initialise.ps1" ]
    floppy_content              = local.core_floppy_content

    # Boot and Provisioner
    boot_order                  = var.vm_boot_order
    boot_wait                   = var.vm_boot_wait
    boot_command                = [ "<spacebar>" ]
    ip_wait_timeout             = var.build_ip_timeout
    communicator                = "winrm"
    winrm_username              = var.admin_username
    winrm_password              = var.admin_password
    shutdown_command            = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Complete\""
    shutdown_timeout            = var.build_shutdown_timeout
}

# -------------------------------------------------------------------------- #
#                             Build Management                               #
# -------------------------------------------------------------------------- #
build {
    # Build sources
    sources                 = [ "source.vsphere-iso.win2019stddexp",
                                "source.vsphere-iso.win2019stdcore" ]
    
    # Windows Update using https://github.com/rgl/packer-provisioner-windows-update
    provisioner "windows-update" {
        pause_before        = "30s"
        search_criteria     = "IsInstalled=0"
        filters             = [ "exclude:$_.Title -like '*VMware*'",
                                "exclude:$_.Title -like '*Preview*'",
                                "exclude:$_.Title -like '*Defender*'",
                                "exclude:$_.InstallationBehavior.CanRequestUserInput",
                                "include:$true" ]
        restart_timeout     = "120m"
    }      
    
    # PowerShell Provisioner to execute scripts 
    provisioner "powershell" {
        elevated_user       = var.admin_username
        elevated_password   = var.admin_password
        scripts             = var.script_files
        environment_vars    = [ "PKISERVER=${ var.build_pkiserver }",
                                "ANSIBLEUSER=${ var.build_configmgmt_user }",
                                "ANSIBLEKEY=${ var.build_configmgmt_key }",
                                "BUILDUSER=${ var.build_username }",
                                "BUILDPASS=${ var.build_password }",
                                "ROOTPEMFILES=${ var.root_pem_files }",
                                "ISSUINGPEMFILES=${ var.issuing_pem_files }" ]
    }

    # PowerShell Provisioner to execute commands
    provisioner "powershell" {
        elevated_user       = var.admin_username
        elevated_password   = var.admin_password
        inline              = var.inline_cmds
    }

    post-processor "manifest" {
        output              = "manifests/vsphere-${source.name}.txt"
        strip_path          = true
        custom_data         = {
            vcenter_fqdn    = var.vcenter_server
            vcenter_folder  = var.vcenter_folder
            iso_file        = var.os_iso_file
            build_repo      = var.build_repo
            build_version   = local.build_version
            build_date      = local.build_date
        }
    }
}