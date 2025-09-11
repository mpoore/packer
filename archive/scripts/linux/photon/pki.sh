#!/bin/bash
# Add trusted certificates
# @author Michael Poore

## Install trusted SSL CA certificates
echo 'Installing trusted SSL CA certificates ...'
IFS=","
rootCerts=($ROOTPEMFILES)
issuingCerts=($ISSUINGPEMFILES)
cd /etc/ssl/certs
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

/usr/bin/rehash_ca_certificates.sh