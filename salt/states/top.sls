# ----------------------------------------------------------------------------
# Name:         salt/states/top.sls
# Description:  Salt top file for Packer provisioning
# Author:       Michael Poore (@mpoore / @mpoore.io)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

base:
  'kernel:Linux':
    - match: grain
    - linux/certificates
    - linux/updates
    - linux/packages
    - linux/disable_ipv6
    - linux/hardening
    - linux/motd
    - linux/ntp
    - linux/issue
    - linux/cloud-init
    - linux/cleanup

  'os:RedHat':
    - match: grain
    - linux/rhsm/rhel_register
    - linux/rhsm/rhel_unregister