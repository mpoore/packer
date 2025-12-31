# ----------------------------------------------------------------------------
# Name:         salt/states/linux/hardening.sls
# Description:  Salt state file for Packer provisioning to harden linux
# Author:       Michael Poore (@mpoore / @mpoore.io)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------
{% set os = grains['os'] %}
{% set hardening_map = {
    'RedHat': 'hardening.redhat',
    'CentOS Stream': 'hardening.redhat',
    'Rocky': 'hardening.redhat',
    'Ubuntu': 'hardening.ubuntu',
    'VMware Photon OS': 'hardening.photon'
} %}

include:
  - {{ hardening_map.get(os, 'hardening.default') }}