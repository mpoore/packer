#!/bin/bash

# Update OS
# @author Michael Poore

echo "Installing snaps: $SNAPS"
IFS=" "
SNAPLIST=($SNAPS)
for SNAP in $SNAPLIST; do
  echo "-- Installing snap: $SNAP ..."
  snap install $SNAP
done

echo "Snap installation completed"