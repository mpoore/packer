# ----------------------------------------------------------------------------
# Name:         salt/states/linux/updates.sls
# Description:  Salt state file for Packer provisioning to apply updates
# Author:       Michael Poore (@mpoore / @mpoore.io)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------
{% set os = grains['os'] %}

# For Debian-based systems like Ubuntu
{% if os == 'Ubuntu' %}
update_packages:
  cmd.run:
    - name: apt-get update && apt-get upgrade -y
    - unless: test -f /var/run/reboot-required
    - order: 1
{% endif %}

# For RHEL-based systems like RHEL or CentOS
{% if os in ['RedHat', 'CentOS Stream', 'Rocky'] %}
dnf_clean_cache:
  cmd.run:
    - name: dnf clean all
    - order: 1

update_packages:
  cmd.run:
    - name: dnf update -y -q
    - env:
        HOME: /root
    - order: 2
{% endif %}

# For Photon OS systems
{% if os == 'VMware Photon OS' %}
update_packages:
  cmd.run:
    - name: tdnf update -y -q
    - order: 1
{% endif %}