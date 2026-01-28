#!/usr/bin/env bash
set -euo pipefail
# DEBUG mode - Prints every command being executed
#set -x
source /usr/local/lib/kira-router/common.lib.sh
verify_root
fail_if_not_installed systemctl pacman

DIR_BIN="/usr/local/bin"
DIR_SYSTEMD="/etc/systemd/system"

echo "Installing blocklist script to $DIR_BIN/arch-automatic-update.sh..."
cp ./bin/arch-automatic-update.sh "$DIR_BIN/arch-automatic-update.sh"

echo "Setting executable permissions on $DIR_BIN/arch-automatic-update.sh..."
chmod +x "$DIR_BIN/arch-automatic-update.sh"

echo "Installing systemd service $DIR_SYSTEMD/arch-automatic-update.service..."
systemctl disable arch-automatic-update.service 2> /dev/null || true
cp ./systemd/arch-automatic-update.service "$DIR_SYSTEMD/arch-automatic-update.service"
cp ./systemd/arch-automatic-update.timer "$DIR_SYSTEMD/arch-automatic-update.timer"

echo "Configuring systemd to use the new service and timer..."
systemctl daemon-reload
systemctl disable arch-automatic-update.service 2> /dev/null || true
systemctl stop arch-automatic-update.service 2> /dev/null || true
systemctl enable arch-automatic-update.timer
