#!/bin/bash
# Configure SSH service
# @author Michael Poore

## Configure SSH server
echo 'Configuring SSH server daemon ...'
sed -i '/^PermitRootLogin/s/yes/no/' /etc/ssh/sshd_config
sed -i "s/.*PubkeyAuthentication.*/PubkeyAuthentication yes/g" /etc/ssh/sshd_config
sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config