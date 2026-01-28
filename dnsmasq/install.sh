#!/usr/bin/env bash
set -euo pipefail
# DEBUG mode - Prints every command being executed
#set -x
source /usr/local/lib/kira-router/common.lib.sh
verify_root
fail_if_not_installed dnsmasq systemctl

DIR_MAIN="/etc"

echo "Replacing dnsmasq configurations..."
rm -f "$DIR_MAIN/dnsmasq.conf"
rm -rf "$DIR_MAIN/dnsmasq.d"
cp ./conf/dnsmasq.conf "$DIR_MAIN"
cp -r ./conf/dnsmasq.d "$DIR_MAIN"

echo "Enabling dnsmasq service..."
systemctl enable dnsmasq
echo "Once you have configured dnsmasq, you can start the service using: systemctl start dnsmasq"
echo "Installation complete!"
