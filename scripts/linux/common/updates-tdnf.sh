#!/bin/bash
# Update OS
# @author Michael Poore

## Apply updates
echo 'Applying package updates ...'
tdnf upgrade tdnf -y --refresh &>/dev/null
tdnf distro-sync -y &>/dev/null