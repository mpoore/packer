# ----------------------------------------------------------------------------
# Name:         salt/states/linux/motd.sls
# Description:  Salt top file for Packer provisioning to configure MOTD
#               and issue
# Author:       Michael Poore (@mpoore / @mpoore.io)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------
{% set os_family = grains['os_family'] %}

{% if os_family == 'RedHat' %}
rhel_motd:
  file.managed:
    - name: /etc/profile.d/motd.sh
    - source: salt://linux/motd/motd.sh
    - file_mode: '0755'

{% elif os_family == 'Debian' %}
debian_motd_reset:
  file.directory:
    - name: /etc/update-motd.d
    - clean: True
    - exclude_pat:
      - 00-motd

debian_motd:      
  file.managed:
    - name: /etc/update-motd.d/00-motd
    - source: salt://linux/motd/motd.sh
    - file_mode: '0755'

{% endif %}