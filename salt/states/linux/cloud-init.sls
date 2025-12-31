# ----------------------------------------------------------------------------
# Name:         salt/states/linux/cloud-init.sls
# Description:  Salt state file for Packer provisioning to install cloud-init
# Author:       Michael Poore (@mpoore / @mpoore.io)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------
{% set os = grains['os'] %}
{% set growpart_pkgs = {
  'Debian': 'cloud-utils',
  'VMware Photon OS': 'cloud-utils',
  'Ubuntu': 'cloud-utils'
} %}
{% set growpart_pkg = growpart_pkgs.get(os, 'cloud-utils-growpart') %}

cloud-init:
  pkg.installed:
    - pkgs:
      - cloud-init
      - perl
      - python3
      - {{ growpart_pkg }}

  file.managed:
    - name: /etc/cloud/cloud.cfg.d/99-vmware-guest-customization.cfg
    - contents: |
        disable_vmware_customization: false
        datasource:
          VMware:
            vmware_cust_file_max_wait: 15
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: cloud-init

  cmd.run:
    - name: cloud-init clean --logs --seed
    - require:
      - file: /etc/cloud/cloud.cfg.d/99-vmware-guest-customization.cfg

enable_ssh_pwauth:
  file.replace:
    - name: /etc/cloud/cloud.cfg
    - pattern: '^ssh_pwauth:.*$'
    - repl: 'ssh_pwauth: true'
    - backup: false
    - require:
      - pkg: cloud-init