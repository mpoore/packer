#!/bin/bash
# Update OS
# @author Michael Poore

## Apply updates
echo 'Updating software list ...'
apt-get update -qq &>/dev/null
echo 'Updating Ubuntu ...'
apt-get upgrade -qq -y &>/dev/null
echo 'Updates completed'