#!/usr/bin/env bash
set -euo pipefail
# DEBUG mode - Prints every command being executed
#set -x
source /usr/local/lib/kira-router/common.lib.sh
verify_root
fail_if_not_installed systemctl dnf

DIR_BIN="/usr/local/bin"
DIR_SYSTEMD="/etc/systemd/system"
echo "Installing blocklist script to $DIR_BIN/fedora-automatic-update.sh..."
cp ./bin/fedora-automatic-update.sh "$DIR_BIN/fedora-automatic-update.sh"

echo "Setting executable permissions on $DIR_BIN/fedora-automatic-update.sh..."
chmod +x "$DIR_BIN/fedora-automatic-update.sh"
echo "Installing systemd service /etc/systemd/system/fedora-automatic-update.service..."
systemctl disable fedora-automatic-update.service 2> /dev/null || true
systemctl disable fedora-automatic-update.timer 2> /dev/null || true

cp ./systemd/fedora-automatic-update.service /etc/systemd/system/fedora-automatic-update.service
cp ./systemd/fedora-automatic-update.timer /etc/systemd/system/fedora-automatic-update.timer
echo "Configuring systemd to use the new service and timer..."

systemctl daemon-reload
systemctl disable fedora-automatic-update.service 2> /dev/null || true
systemctl stop fedora-automatic-update.service 2> /dev/null || true
systemctl enable fedora-automatic-update.timer
