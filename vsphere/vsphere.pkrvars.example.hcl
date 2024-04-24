# ----------------------------------------------------------------------------
# Name:         vsphere.pkrvars.hcl
# Description:  Required vSphere variables for Packer builds
# Author:       Michael Poore (@mpoore)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

vcenter_username        = "administrator@vsphere.local"
vcenter_password        = "VMware1!"
admin_password          = "VMware1!"
build_username          = "build"
build_password          = "VMware1!"
rhsm_user               = "rhsmuser"
rhsm_pass               = "rhsmpass"

vcenter_server          = "vcenter.fqdn"
vcenter_datacenter      = "datacenter"
vcenter_cluster         = "cluster"
vcenter_folder          = "templates"
vcenter_datastore       = "datastore"
vcenter_network         = "network"
vcenter_iso_datastore   = "datastore"
vcenter_content_library = "contentlibrary"
root_pem_files          = [ "http://cert.fqdn/root.crt" ]
issuing_pem_files       = [ "http://cert.fqdn/issuing.crt" ]