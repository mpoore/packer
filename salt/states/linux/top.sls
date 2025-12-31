# ----------------------------------------------------------------------------
# Name:         salt/states/top.sls
# Description:  Salt top file for Packer provisioning
# Author:       Michael Poore (@mpoore / @mpoore.io)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

base:
  'kernel:Linux':
    - match: grain
    - certificates
    - packages
    - disable_ipv6
    - hardening
    - motd
    - ntp
    - issue
    - cloud-init
    - salt-minion
    - cleanup

  'os:RedHat':
    - match: grain
    - rhel/rhel_register
    - rhel/rhel_unregister