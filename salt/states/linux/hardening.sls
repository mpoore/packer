# ----------------------------------------------------------------------------
# Name:         salt/states/linux/hardening.sls
# Description:  Salt state file for Packer provisioning to harden linux
# Author:       Michael Poore (@mpoore / @mpoore.io)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------
{% set os = grains['os'] %}
{% set hardening_map = {
    'RedHat': 'linux.hardening.redhat',
    'CentOS Stream': 'linux.hardening.redhat',
    'Rocky': 'linux.hardening.redhat',
    'Ubuntu': 'linux.hardening.ubuntu',
    'VMware Photon OS': 'linux.hardening.photon'
} %}

include:
  - {{ hardening_map.get(os, 'linux.hardening.default') }}