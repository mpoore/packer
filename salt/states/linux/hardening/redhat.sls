# ----------------------------------------------------------------------------
# Name:         salt/states/linux/hardening/redhat.sls
# Description:  Salt state file for Packer provisioning to harden RHEL
# Author:       Michael Poore (@mpoore / @mpoore.io)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

# Ensure firewalld is installed and enabled
firewalld:
  pkg.installed:
    - name: firewalld
  service.running:
    - name: firewalld
    - enable: True

# Ensure SELinux is enforcing
selinux-enforcing:
  file.managed:
    - name: /etc/selinux/config
    - contents: |
        SELINUX=enforcing
    - mode: '0644'

# Password Complexity & Aging
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

password-aging:
  file.managed:
    - name: /etc/login.defs
    - contents: |
        PASS_MAX_DAYS   90
        PASS_MIN_DAYS   7
        PASS_WARN_AGE   7
    - mode: '0644'

# Disable root login via SSH and enforce key authentication
ssh-hardening:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: '^PermitRootLogin yes'
    - repl: 'PermitRootLogin no'
  service.running:
    - name: sshd
    - watch:
      - file: ssh-hardening

# Install and configure auditd
auditd:
  pkg.installed:
    - name: audit
  service.running:
    - name: auditd
    - enable: True

auditd-rules:
  file.managed:
    - name: /etc/audit/rules.d/cis.rules
    - contents: |
        -w /etc/passwd -p wa -k identity
        -w /etc/shadow -p wa -k identity
        -w /var/log/ -p wa -k logs
    - mode: '0600'

# Remove unnecessary services
remove-unwanted-services:
  pkg.removed:
    - pkgs:
        - telnet
        - rsh-server
        - ypserv
        - tftp

# Enable automatic updates
{% if grains['osmajorrelease']|int >= 8 %}
enable-auto-updates:
  pkg.installed:
    - pkgs:
        - dnf-automatic
  service.running:
    - name: dnf-automatic.timer
    - enable: True
{% endif %}

# Kernel Hardening via sysctl
kernel-hardening:
  file.append:
    - name: /etc/sysctl.conf
    - text:
        - net.ipv4.conf.all.send_redirects = 0
        - net.ipv4.icmp_ignore_bogus_error_responses = 1
        - kernel.randomize_va_space = 2
  cmd.run:
    - name: sysctl --system

# Logging Enhancements
journald-persistence:
  file.managed:
    - name: /etc/systemd/journald.conf
    - contents: |
        [Journal]
        Storage=persistent
        Compress=yes
    - mode: 0644
  service.running:
    - name: systemd-journald

# Set strict ingress / egress rules
firewalld-segmentation:
  cmd.run:
    - name: |
        firewall-cmd --permanent --zone=public --add-service=ssh
        firewall-cmd --permanent --zone=public --add-service=http
        firewall-cmd --permanent --zone=public --remove-service=telnet
        firewall-cmd --reload
  service.running:
    - name: firewalld

# Disable USB storage devices
disable-usb-storage:
  file.managed:
    - name: /etc/modprobe.d/usb-storage.conf
    - contents: "install usb-storage /bin/true"
    - mode: 0644
  cmd.run:
    - name: rmmod usb-storage
    - onlyif: lsmod | grep -q usb_storage