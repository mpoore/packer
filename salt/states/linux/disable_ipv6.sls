# ----------------------------------------------------------------------------
# Name:         salt/states/linux/disable_ipv6.sls
# Description:  Salt state file for Packer provisioning to disable IPv6
# Author:       Michael Poore (@mpoore / @mpoore.io)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------
{% set os = grains['os'] %}

{% if os == 'Ubuntu' %}
Disable IPv6 on Ubuntu:
  file.managed:
    - name: /etc/sysctl.d/99-disable-ipv6.conf
    - contents: |
        net.ipv6.conf.all.disable_ipv6 = 1
        net.ipv6.conf.default.disable_ipv6 = 1
        net.ipv6.conf.lo.disable_ipv6 = 1

{% elif os in ['RedHat', 'CentOS Stream', 'Rocky'] %}
Disable IPv6 in RHEL:
  file.append:
    - name: /etc/default/grub
    - text:
      - GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX ipv6.disable=1"
  cmd.run:
    - name: grub2-mkconfig -o /boot/grub2/grub.cfg

{% elif os == 'VMware Photon OS' %}
Disable IPv6 on Photon OS:
  file.managed:
    - name: /etc/systemd/network/99-disable-ipv6.network
    - contents: |
        [Match]
        Name=*

        [Network]
        IPv6AcceptRA=no
        LinkLocalAddressing=no
{% endif %}