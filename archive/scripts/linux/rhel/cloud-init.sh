#!/bin/bash
# Configure cloud-init
# @author Michael Poore

## Install cloud-init
echo 'Installing cloud-init ...'
dnf install -y -q cloud-init perl python3 cloud-utils-growpart &>/dev/null

## Configure cloud-init
echo 'Configuring cloud-init ...'
cat << EOF > /etc/cloud/cloud.cfg.d/99-vmware-guest-customization.cfg
disable_vmware_customization: false
datasource:
  VMware:
    vmware_cust_file_max_wait: 20
EOF
cloud-init clean --logs --seed
sed -i '/^ssh_pwauth/s/0/1/' /etc/cloud/cloud.cfg