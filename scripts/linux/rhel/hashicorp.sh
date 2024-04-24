#!/bin/bash
# Configure HashiCorp repository
# @author Michael Poore

## Adding hashicorp repository
echo 'Adding HashiCorp repository ...'
wget -q -O- https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo | tee /etc/yum.repos.d/hashicorp.repo &>/dev/null