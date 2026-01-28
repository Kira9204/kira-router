#!/usr/bin/env bash
set -euo pipefail
# DEBUG mode - Prints every command being executed
#set -x
source /usr/local/lib/kira-router/common.lib.sh
verify_root
fail_if_not_installed systemctl networkctl

DIR_CONF="/etc/systemd/network"

echo "Installing configurations at $DIR_CONF..."
mkdir -p "$DIR_CONF"
cp ./conf/*.network "$DIR_CONF"
cp ./conf/*.link "$DIR_CONF"
systemctl deamon-reload
systemctl enable systemd-networkd
echo "To start the service now, run: systemctl restart systemd-networkd"
echo "Installation complete!"
echo "You can manage the network using: networkctl [status|list|up|down] <interface>"
