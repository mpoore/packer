#!/bin/bash
# Configure power profile and screen settings
# @author Michael Poore

# Configure power profile
echo 'Configuring power profile ...'
gsettings set org.mate.power-manager sleep-computer-ac 0
gsettings set org.mate.power-manager sleep-display-ac 0