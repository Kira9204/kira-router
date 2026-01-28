#!/usr/bin/env bash
set -euo pipefail
# DEBUG mode - Prints every command being executed
#set -x
source /usr/local/lib/kira-router/common.lib.sh
verify_root
fail_if_not_installed systemctl unbound curl

DIR_BIN="/usr/local/bin"
DIR_SYSTEMD="/etc/systemd/system"

echo "Installing blocklist script to $DIR_BIN/blocklist.sh..."
cp ./bin/blocklist.sh "$DIR_BIN/blocklist.sh"

echo "Setting executable permissions on $DIR_BIN/blocklist.sh..."
chmod +x "$DIR_BIN/blocklist.sh"

echo "Installing systemd service $DIR_SYSTEMD/blocklist.service..."
systemctl disable blocklist.service 2> /dev/null || true
systemctl disable blocklist.timer 2> /dev/null || true
cp ./systemd/blocklist.service "$DIR_SYSTEMD/blocklist.service"
cp ./systemd/blocklist.timer "$DIR_SYSTEMD/blocklist.timer"
systemctl daemon-reload
systemctl enable blocklist.timer
systemctl start blocklist.timer
