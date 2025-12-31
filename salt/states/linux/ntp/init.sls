# ----------------------------------------------------------------------------
# Name:         salt/states/linux/ntp/init.sls
# Description:  Salt state file for Packer provisioning to configure NTP
# Author:       Michael Poore (@mpoore / @mpoore.io)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------
{% set chrony_conf_file = '/etc/chrony.conf' %}

# Install Chrony
configure_chrony:
  pkg.latest:
    - name: chrony
    - refresh: True

  file.managed:
    - name: {{ chrony_conf_file }}
    - source: salt://ntp/chrony.conf.j2
    - template: jinja
    - replace: True

  service.running:
    - name: chronyd
    - enable: True
    - watch:
        - file: {{ chrony_conf_file }}