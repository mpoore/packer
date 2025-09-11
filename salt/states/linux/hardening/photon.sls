# ----------------------------------------------------------------------------
# Name:         salt/states/linux/hardening/photon.sls
# Description:  Salt state file for Packer provisioning to harden Photon OS
# Author:       Michael Poore (@mpoore / @mpoore.io)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

# Ensure iptables is installed and enabled
iptables:
  pkg.installed:
    - name: iptables
  service.running:
    - name: iptables
    - enable: True

# Ensure root password policy
password-policy:
  file.managed:
    - name: /etc/security/pwquality.conf
    - contents: |
        minlen = 14
        dcredit = -1
        ucredit = -1
        ocredit = -1
        lcredit = -1
    - mode: '0644'

# Disable root SSH access
disable-root-ssh:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: '^PermitRootLogin yes'
    - repl: 'PermitRootLogin no'
    - backup: True
  service.running:
    - name: sshd
    - watch:
      - file: disable-root-ssh