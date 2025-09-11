# ----------------------------------------------------------------------------
# Name:         salt/states/linux/packages.sls
# Description:  Salt state file for Packer provisioning to install base
#               packages
# Author:       Michael Poore (@mpoore / @mpoore.io)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------
{% set os = grains['os'] %}
{% set pkg_list = pillar.get('packages', {}).get(os, []) %}

common-packages:
  pkg.installed:
    - pkgs: {{ pkg_list }}