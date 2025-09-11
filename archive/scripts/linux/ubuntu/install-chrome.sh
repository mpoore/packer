#!/bin/bash
# Install Google Chrome Browser
# @author Michael Poore

echo 'Installing Google Chrome ...'
cd /tmp
echo '-- Downloading Chrome ...'
wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb &>/dev/null

echo '-- Installing Chrome ...'
apt install -qq -y -f /tmp/google-chrome-stable_current_amd64.deb &>/dev/null