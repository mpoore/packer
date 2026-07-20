# ----------------------------------------------------------------------------
# Name:         rocky9.pkr.hcl
# Description:  Build definition for Rocky Linux 9
# Author:       Michael Poore (@mpoore)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

# -------------------------------------------------------------------------- #
#                           Packer Configuration                             #
# -------------------------------------------------------------------------- #
packer {
    required_version = ">= 1.15.4"
    required_plugins {
        vsphere = {
            version = ">= 2.2.0"
            source  = "github.com/hashicorp/vsphere"
        }
        salt = {
            version = ">= 0.6.0"
            source  = "github.com/mpoore/salt"
        }
    }
}

# -------------------------------------------------------------------------- #
#                              Local Variables                               #
# -------------------------------------------------------------------------- #
locals {
    build_name_suffix           = var.build_branch == "main" ? "" : "-${ var.build_branch }"
    is_release_branch           = contains(["main", "dev"], var.build_branch)
    build_version               = formatdate("YY.MM-DD", timestamp())
    build_date                  = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
    ks_content                  = {
                                    "ks.cfg" = templatefile("${abspath(path.root)}/cfg/ks.pkrtpl.hcl", {
                                        build_username            = var.build_username
                                        build_password            = var.build_password
                                        build_password_encrypted  = var.build_password_encrypted
                                        build_guestos_language    = var.build_guestos_language
                                        build_guestos_keyboard    = var.build_guestos_keyboard
                                        build_guestos_timezone    = var.build_guestos_timezone
                                        build_guestos_packages    = join(" ", var.build_guestos_packages)
                                        salt_version              = var.salt_version
                                    })
                                  }
    vm_description              = "OS: ${ var.meta_os_vendor } ${ var.meta_os_family } ${ var.meta_os_version }\nVER: ${ local.build_version } (${ var.build_branch })\nDATE: ${ local.build_date }\nISO: ${ var.os_iso_file }"
}

# -------------------------------------------------------------------------- #
#                       Template Source Definitions                          #
# -------------------------------------------------------------------------- #
source "vsphere-iso" "rocky9" {
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
    convert_to_template         = var.vcenter_convert_template && local.is_release_branch
    create_snapshot             = var.vcenter_snapshot
    snapshot_name               = var.vcenter_snapshot_name
    dynamic "content_library_destination" {
        for_each = (var.vcenter_content_library != null && local.is_release_branch) ? [1] : []
            content {
                library         = var.vcenter_content_library
                name            = "${ source.name }${ local.build_name_suffix }"
                description     = local.vm_description
                ovf             = var.vcenter_content_library_ovf
                destroy         = var.vcenter_content_library_destroy
                skip_import     = var.vcenter_content_library_skip
            }
    }

    # Virtual Machine
    guest_os_type               = var.build_guestos_type
    vm_name                     = "${ source.name }${ local.build_name_suffix }"
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
    cd_content                  = local.ks_content

    # Boot and Provisioner
    boot_order                  = var.vm_boot_order
    boot_wait                   = var.vm_boot_wait
    boot_command                = [ "up", "wait", "e", "<down><down><end><wait>",
                                    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
                                    "quiet text inst.ks=cdrom",
                                    "<enter><wait><leftCtrlOn>x<leftCtrlOff>" ]
    ip_wait_timeout             = var.build_ip_timeout
    communicator                = "ssh"
    ssh_username                = var.build_username
    ssh_password                = var.build_password
    ssh_timeout                 = var.build_ssh_timeout
    shutdown_command            = "sudo shutdown -P now"
    shutdown_timeout            = var.build_shutdown_timeout
}

# -------------------------------------------------------------------------- #
#                             Build Management                               #
# -------------------------------------------------------------------------- #
build {
    # Build sources
    sources                 = [ "source.vsphere-iso.rocky9" ]

    # Salt State provisioning
    provisioner "salt" {
        state_tree          = var.state_tree
        pillar_tree         = var.pillar_tree
        environment_vars    = [ "BUILDVERSION=${ local.build_version }", "BUILDDATE=${ local.build_date }", "BUILDBRANCH=${ var.build_branch }" ]
    }

    post-processor "manifest" {
        output              = "manifests/vsphere-${source.name}.txt"
        strip_path          = true
        custom_data         = {
            vcenter_fqdn    = var.vcenter_server
            vcenter_folder  = var.vcenter_folder
            iso_file        = var.os_iso_file
            build_branch    = var.build_branch
            build_repo      = var.build_repo
            build_version   = local.build_version
            build_date      = local.build_date
        }
    }
}