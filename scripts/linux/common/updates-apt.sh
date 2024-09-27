#!/bin/bash
# Update OS
# @author Michael Poore

## Apply updates
echo 'Applying package updates ...'
apt-get update -y -q &>/dev/null