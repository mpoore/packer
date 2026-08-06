#!/usr/bin/env bash
# Echoes the Packer CI image version and installed plugins into the job log,
# reading the VERSION and PLUGINS files baked into the image at build time.
set -euo pipefail

echo "=========================================================================================="
echo "Packer CI image source : $1" 
if [[ -f /VERSION ]]; then
    echo "Packer CI image version: $(jq -r '.version' /VERSION)"
else
    echo "Packer CI image version: unknown (/VERSION not found)"
fi

if [[ -f /PLUGINS ]]; then
    echo "Installed plugins:"
    jq -r '.plugins[] | "  - \(.name) \(.version)  (\(.source))"' /PLUGINS
else
    echo "Installed plugins: unknown (/PLUGINS not found)"
fi
echo "=========================================================================================="