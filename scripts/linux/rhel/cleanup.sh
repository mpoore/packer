#!/bin/bash
# Cleanup template for vSphere cloning
# @author Michael Poore

## Cleanup dnf
echo 'Clearing dnf cache ...'
dnf clean all &>/dev/null

## Final cleanup actions
echo 'Executing final cleanup tasks ...'
# Udev rules
if [ -f /etc/udev/rules.d/70-persistent-net.rules ]; then
    rm -f /etc/udev/rules.d/70-persistent-net.rules
fi
# Network scripts
rm -f /etc/sysconfig/network-scripts/*
# Temp directories
rm -rf /tmp/*
rm -rf /var/tmp/*
rm -rf /var/cache/dnf/*
# Machine id
truncate -s 0 /etc/machine-id
# SSH keys
rm -f /etc/ssh/ssh_host_*
# Audit logs
if [ -f /var/log/audit/audit.log ]; then
    cat /dev/null > /var/log/audit/audit.log
fi
if [ -f /var/log/wtmp ]; then
    cat /dev/null > /var/log/wtmp
fi
if [ -f /var/log/lastlog ]; then
    cat /dev/null > /var/log/lastlog
fi
# Clean history
history -cw
echo > ~/.bash_history
rm -fr /root/.bash_history
# Finished
echo 'Configuration complete'