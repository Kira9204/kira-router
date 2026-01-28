#!/usr/bin/env bash
set -euo pipefail
# DEBUG mode - Prints every command being executed
#set -x
source /usr/local/lib/kira-router/common.lib.sh
verify_root
echo "Installing chrony NTP configuration to /etc/chrony.conf..."
cp ./conf/chrony.conf /etc/chrony.conf
echo "Restarting chronyd service to apply new configuration..."
systemctl restart chronyd
echo "Installation complete!"
