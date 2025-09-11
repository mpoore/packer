# ----------------------------------------------------------------------------
# Name:         salt/states/linux/hardening/ubuntu.sls
# Description:  Salt state file for Packer provisioning to harden Ubuntu
# Author:       Michael Poore (@mpoore / @mpoore.io)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

# Ensure UFW is installed and enabled
ufw:
  pkg.installed:
    - name: ufw
  service.running:
    - name: ufw
    - enable: True

# Ensure password complexity requirements
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

# Disable root login via SSH
disable-root-ssh:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: '^PermitRootLogin yes'
    - repl: 'PermitRootLogin no'
    - backup: True