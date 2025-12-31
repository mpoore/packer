# ----------------------------------------------------------------------------
# Name:         salt/pillars/top.sls
# Description:  Salt top file for Packer provisioning
# Author:       Michael Poore (@mpoore / @mpoore.io)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

base:
  '*':
    - certificates
    - issue
    - ntp
    - packages