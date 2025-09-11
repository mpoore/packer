#!/bin/bash
# Add trusted certificates
# @author Michael Poore

## Install ca certificates
echo 'Installing ca-certificates package ...'
dnf install -y -q ca-certificates &>/dev/null

## Install trusted SSL CA certificates
echo 'Installing trusted SSL CA certificates ...'
IFS=","
rootCerts=($ROOTPEMFILES)
issuingCerts=($ISSUINGPEMFILES)
cd /etc/pki/ca-trust/source/anchors
if [[ -n $ROOTPEMFILES ]]
then
    for cert in $rootCerts; do
    echo "Downloading $cert ..."
    wget -q $cert &>/dev/null
    done
fi

if [[ -n $ISSUINGPEMFILES ]]
then
    for cert in $issuingCerts; do
    echo "Downloading $cert ..."
    wget -q $cert &>/dev/null
    done
fi

update-ca-trust extract