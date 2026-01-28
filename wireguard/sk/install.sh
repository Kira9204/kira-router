#!/usr/bin/env bash
set -euo pipefail
# DEBUG mode - Prints every command being executed
#set -x
source /usr/local/lib/kira-router/common.lib.sh
verify_root
fail_if_not_installed ip nft wg systemctl

DIR_CONF="/etc/wireguard/sk"
DIR_BIN="/usr/local/bin"
DIR_SYSTEMD="/etc/systemd/system"

echo "Installing configurations at $DIR_CONF..."
if [ ! -d "$DIR_CONF" ]; then
  mkdir -p "$DIR_CONF"
fi
cp ./conf/wg.conf "$DIR_CONF"
echo "Installing main script at $DIR_BIN/wg-sk.sh..."
cp ./bin/wg-sk.sh "$DIR_BIN"

echo "Setting executable permissions on $DIR_BIN/wg-sk.sh..."
chmod +x "$DIR_BIN/wg-sk.sh"

echo "Installing and enabling systemd service $DIR_SYSTEMD/wg-sk.service..."
systemctl stop wg-sk.service 2> /dev/null || true
systemctl disable wg-sk.service 2> /dev/null || true
cp ./conf/wg-sk.service "$DIR_SYSTEMD"
systemctl daemon-reload
systemctl enable wg-sk.service
echo "To start the service now, run: systemctl start wg-sk.service"

echo "Installation complete!"
echo "You can run the main script using: wg-sk.sh [start|stop]"
