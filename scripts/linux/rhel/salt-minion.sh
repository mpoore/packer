#!/bin/bash
# Configure salt-minion
# @author Michael Poore

## Adding salt repository
echo 'Adding salt repository ...'
curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.repo | sudo tee /etc/yum.repos.d/salt.repo &>/dev/null

## Install salt-minion
echo 'Installing salt-minion ...'
dnf install -y -q salt-minion &>/dev/null

## Configure salt-minion
echo '-- Configuring salt-minion ...'
cat << EOF > /usr/lib/systemd/system/salt-minion.timer
[Unit]
Description=Timer for the salt-minion service

[Timer]
OnBootSec=2min

[Install]
WantedBy=timers.target
EOF
systemctl enable salt-minion.timer &>/dev/null