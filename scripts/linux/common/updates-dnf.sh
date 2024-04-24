#!/bin/bash
# Update OS
# @author Michael Poore

## Apply updates
echo 'Applying package updates ...'
dnf upgrade -y -q &>/dev/null