#!/bin/bash
# Unregister from RHSM
# @author Michael Poore

## Unregister from RHSM
echo 'Unregistering from Red Hat Subscription Manager ...'
subscription-manager remove --all &>/dev/null
subscription-manager unregister &>/dev/null
subscription-manager clean &>/dev/null
rm -rf /var/log/rhsm/*