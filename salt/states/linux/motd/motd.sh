#!/bin/sh
# ----------------------------------------------------------------------------
# Name:         salt/linux/motd/motd.sh
# Description:  MoTD script
# Author:       Michael Poore (@mpoore / @mpoore.io)
# URL:          https://github.com/mpoore/packer
# ----------------------------------------------------------------------------

# System Information
USER=$(whoami)
HOSTNAME=$(hostname)
UPTIME=$(uptime -p | awk '{$1=""; print substr($0,2)}')
LAST_LOGIN=$(last -n 1 $USER | head -n 1 | awk '{ print $3, $4, $5, $6 }')
LOAD=$(uptime | awk '{print $9,$10,$11}' | sed 's/,//g')

clear
echo "  ***************************************************************************"
echo "  * Unauthorized access to this system is prohibited.                       *"
echo "  * Only authorized users may access this system.                           *"
echo "  * All activity may be monitored, recorded, and subject to audit.          *"
echo "  * By accessing this system, you consent to these terms.                   *"
echo "  * If you are not authorized to use this system, disconnect immediately.   *"
echo "  ***************************************************************************"
echo ""
echo "  Welcome, $USER!"
echo ""
echo "     hostname :    $HOSTNAME"
echo "       uptime :    $UPTIME"
echo "        login :    $LAST_LOGIN"
echo "         load :    $LOAD"
echo ""