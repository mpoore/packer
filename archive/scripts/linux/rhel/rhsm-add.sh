#!/bin/bash
# Register to RHSM
# @author Michael Poore

## Register with RHSM
echo 'Registering with RedHat Subscription Manager ...'
subscription-manager register --username $RHSM_USER --password $RHSM_PASS --auto-attach &>/dev/null