# ----------------------------------------------------------------------------
# Name:         ubuntu2404.pkr.hcl
# Description:  Build definition for Ubuntu 24.04 LTS
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
            source  = "github.com/hashicorp/vsphere"
            version = ">= 1.4.0"
        }
    }
}

# -------------------------------------------------------------------------- #
#                              Local Variables                               #
# -------------------------------------------------------------------------- #
locals { 
    build_version               = formatdate("YY.MM (DD.hhmm)", timestamp())
    build_date                  = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
    data_source_content         = {
                                    "/meta-data" = file("${abspath(path.root)}/data/meta-data")
                                    "/user-data" = templatefile("${abspath(path.root)}/data/user-data.pkrtpl.hcl", {
                                        build_username            = var.build_username
                                        build_password_encrypted  = var.build_password_encrypted
                                        build_guestos_language    = var.build_guestos_language
                                        build_guestos_keyboard    = var.build_guestos_keyboard
                                        build_guestos_timezone    = var.build_guestos_timezone
                                        build_guestos_packages    = var.build_guestos_packages
                                    })
                                  }
    vm_description              = "VER: ${ local.build_version }\nISO: ${ var.os_iso_file }"
}

# -------------------------------------------------------------------------- #
#                       Template Source Definitions                          #
# -------------------------------------------------------------------------- #
source "vsphere-iso" "ubuntu2404" {
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
    iso_paths                   = [ "[${ var.vcenter_iso_datastore }] ${ var.os_iso_path }/${ var.os_iso_file }" ]
    cd_content                  = local.data_source_content
    cd_label                    = "cidata"

    # Boot and Provisioner
    boot_order                  = var.vm_boot_order
    boot_wait                   = var.vm_boot_wait
    boot_command                = [ "c<wait>",
                                    "linux /casper/vmlinuz --- autoinstall",
                                    "<enter><wait>",
                                    "initrd /casper/initrd",
                                    "<enter><wait>",
                                    "boot",
                                    "<enter>" ]
    ip_wait_timeout             = var.build_ip_timeout
    communicator                = "ssh"
    ssh_username                = var.build_username
    ssh_password                = var.build_password
    ssh_timeout                 = "30m"
    shutdown_command            = "echo '${ var.build_password }' | sudo shutdown -h now"
    shutdown_timeout            = var.build_shutdown_timeout
}

# -------------------------------------------------------------------------- #
#                             Build Management                               #
# -------------------------------------------------------------------------- #
build {
    # Build sources
    sources                 = [ "source.vsphere-iso.ubuntu2404" ]
    
    # Shell Provisioner to execute scripts
    provisioner "shell" {
        execute_command     = "echo '${ var.build_password }' | {{.Vars}} sudo -E -S sh -eu '{{.Path}}'"
        scripts             = var.script_files
        environment_vars    = [ "PKISERVER=${ var.build_pkiserver }",
                                "CONFIGMGMTUSER=${ var.build_configmgmt_user }",
                                "CONFIGMGMTKEY=${ var.build_configmgmt_key }",
                                "BUILDVERSION=${ local.build_version }",
                                "BUILDREPO=${ var.build_repo }",
                                "RHSM_USER=${ var.rhsm_user }",
                                "RHSM_PASS=${ var.rhsm_pass }",
                                "ROOTPEMFILES=${ join(",",var.root_pem_files) }",
                                "ISSUINGPEMFILES=${ join(",",var.issuing_pem_files) }",
                                "OS_VERSION=${ var.meta_os_version }" ]
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