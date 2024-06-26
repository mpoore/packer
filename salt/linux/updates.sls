# update.sls

{% if grains['os_family'] == 'Debian' %}
# For Debian-based systems like Debian, Ubuntu
update_packages:
  cmd.run:
    - name: apt-get update && apt-get upgrade -y
    - require:
      - cmd: apt_get_update
      - cmd: apt_get_upgrade

apt_get_update:
  cmd.run:
    - name: apt-get update

apt_get_upgrade:
  cmd.run:
    - name: apt-get upgrade -y

{% elif grains['os_family'] == 'RedHat' %}
# For RedHat-based systems like RHEL, CentOS, Fedora
update_packages:
  cmd.run:
    - name: yum update -y -q

{% elif grains['os_family'] == 'Suse' %}
# For SUSE-based systems like openSUSE, SLES
update_packages:
  cmd.run:
    - name: zypper refresh && zypper update -y

{% elif grains['os_family'] == 'Arch' %}
# For Arch-based systems
update_packages:
  cmd.run:
    - name: pacman -Syu --noconfirm

{% else %}
# For other Linux systems
update_packages:
  cmd.run:
    - name: echo "Unsupported OS family: {{ grains['os_family'] }}"

{% endif %}