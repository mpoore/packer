#!/bin/bash
# Configure salt-minion
# @author Michael Poore

## Adding salt repository
echo 'Adding salt repository ...'
major_version=$(echo $OS_VERSION | cut -d '.' -f 1)
echo "-- OS major version: $major_version"
rpm --import https://repo.saltproject.io/salt/py3/redhat/$major_version/x86_64/SALT-PROJECT-GPG-PUBKEY-2023.pub &>/dev/null
curl -fsSL https://repo.saltproject.io/salt/py3/redhat/$major_version/x86_64/latest.repo | tee /etc/yum.repos.d/salt.repo &>/dev/null

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