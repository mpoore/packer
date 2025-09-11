#!/bin/sh
# ----------------------------------------------------------------------------
# Name:         local.sh
# Description:  Script to set ESX hostname and management IP settings
#               from guestinfo properties for nested ESX
# Author:       Michael Poore (@mpoore)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

LOG_FILE="/var/log/vapp-init.log"
exec >> "$LOG_FILE" 2>&1

echo "$(date) - Starting vApp configuration..."

get_guestinfo() {
    /usr/bin/vmtoolsd --cmd "info-get guestinfo.$1" 2>/dev/null
}

CURRENT_HOSTNAME=$(hostname)
CURRENT_IP=$(localcli network ip interface ipv4 get | grep vmk0 | awk '{print $2}')
CURRENT_GATEWAY=$(esxcli network ip route ipv4 list | awk '/default/ {print $1}')

echo "$(date) - Current hostname: $CURRENT_HOSTNAME"
echo "$(date) - Current IP:       $CURRENT_IP"
echo "$(date) - Current gateway:  $CURRENT_GATEWAY"

# Get vApp properties
VAPP_HOSTNAME=$(get_guestinfo network.mgmt.hostname)
VAPP_IP=$(get_guestinfo network.mgmt.ip)
VAPP_NETMASK=$(get_guestinfo network.mgmt.netmask)
VAPP_GATEWAY=$(get_guestinfo network.mgmt.gateway)
VAPP_DNS=$(get_guestinfo network.mgmt.dns)
VAPP_NTP=$(get_guestinfo network.mgmt.ntp)
VAPP_DOMAIN=$(get_guestinfo network.mgmt.domain)
VAPP_VLAN=$(get_guestinfo network.mgmt.vlan)

NEED_REBOOT=0
NEED_CERT_REGEN=0

# Update network mgmt hostname
if [ -n "$VAPP_HOSTNAME" ] && [ "$VAPP_HOSTNAME" != "$CURRENT_HOSTNAME" ]; then
    echo "$(date) - Changing hostname to $VAPP_HOSTNAME"
    esxcli system hostname set --host="$VAPP_HOSTNAME"
    NEED_CERT_REGEN=1
    NEED_REBOOT=1
fi

# Update network mgmt IP details
if [ -n "$VAPP_IP" ] && [ "$VAPP_IP" != "$CURRENT_IP" ]; then
    echo "$(date) - Changing IP to $VAPP_IP/$VAPP_NETMASK via $VAPP_GATEWAY"
    esxcli network ip interface ipv4 set -i vmk0 -I "$VAPP_IP" -N "$VAPP_NETMASK" -t static
    esxcli network ip route ipv4 remove --network=default
    esxcli network ip route ipv4 add --gateway="$VAPP_GATEWAY" --network=default
    NEED_REBOOT=1

    # Update network mgmt DNS servers
    if [ -n "$VAPP_DNS" ]; then
        echo "$(date) - Setting DNS servers to $VAPP_DNS"
        esxcli network ip dns server remove --all
        DNS_LIST="${VAPP_DNS//,/ }"
        for dns in $DNS_LIST; do
            esxcli network ip dns server add --server="$dns"
        done
    fi

    if [ -n "$VAPP_DOMAIN" ]; then
        echo "$(date) - Setting DNS search domain to $VAPP_DOMAIN"
        esxcli network ip dns search add --domain="$VAPP_DOMAIN"
    fi

    # VLAN ID change
    if [ -n "$VAPP_VLAN" ]; then
        PG_NAME=$(esxcli network vswitch standard portgroup list | grep vmk0 | awk '{print $1}')
        if [ -n "$PG_NAME" ]; then
            CURRENT_VLAN=$(esxcli network vswitch standard portgroup get -p "$PG_NAME" | awk -F ': ' '/VLAN ID/ {print $2}')
            if [ "$VAPP_VLAN" != "$CURRENT_VLAN" ]; then
                echo "$(date) - Changing VLAN ID of portgroup $PG_NAME to $VAPP_VLAN"
                esxcli network vswitch standard portgroup set -p "$PG_NAME" -v "$VAPP_VLAN"
                NEED_REBOOT=1
            fi
        else
            echo "$(date) - Warning: Unable to determine portgroup for vmk0"
        fi
    fi
fi

# Update network time servers
if [ -n "$VAPP_NTP" ]; then
    echo "$(date) - Setting NTP servers to $VAPP_NTP"
    esxcli system ntp set --server "$VAPP_NTP"
    echo "$(date) - Enabling NTP service"
    esxcli system ntp set --enabled true
fi

# Regenerate certs
if [ "$NEED_CERT_REGEN" -eq 1 ]; then
    echo "$(date) - Regenerating certificates"
    /sbin/generate-certificates
fi

# Reboot if required
if [ "$NEED_REBOOT" -eq 1 ]; then
    echo "$(date) - Rebooting to apply changes..."
    reboot
fi

echo "$(date) - vApp configuration completed."

exit 0