# ----------------------------------------------------------------------------
# Name:         salt/pillars/linux/packages.sls
# Description:  Salt pillar file for linux package installations
# Author:       Michael Poore (@mpoore / @mpoore.io)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------
packages:
  RedHat:
    - curl
    - git
    - net-tools
    - vim-enhanced
    - wget
    - telnet
    - dbus-tools
    - openssl

  Rocky:
    - curl
    - git
    - net-tools
    - vim-enhanced
    - wget

  CentOS Stream:
    - curl
    - git
    - net-tools
    - vim-enhanced
    - wget

  Ubuntu:
    - curl
    - git
    - net-tools
    - openssl
    - vim
    - wget

  VMware Photon OS:
    - curl
    - git
    - net-tools
    - vim
    - wget