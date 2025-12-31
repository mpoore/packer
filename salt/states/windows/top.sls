# ----------------------------------------------------------------------------
# Name:         salt/states/top.sls
# Description:  Salt top file for Packer provisioning
# Author:       Michael Poore (@mpoore / @mpoore.io)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

base:
  'kernel:Windows':
    - match: grain
    - hibernation