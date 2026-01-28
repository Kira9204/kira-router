#!/usr/bin/env bash
set -euo pipefail
# DEBUG mode - Prints every command being executed
#set -x
source /usr/local/lib/kira-router/common.lib.sh
verify_root
fail_if_not_installed systemctl curl

DIR_BIN="/usr/local/bin"
DIR_SYSTEMD="/etc/systemd/system"

TOKEN_DIR="/etc/kira-router/ddns/digital-ocean"
TOKEN_FILE="$TOKEN_DIR/token.sh"
echo "Adding config directory $TOKEN_DIR..."
if [ ! -d "$TOKEN_DIR" ]; then
  mkdir -p "$TOKEN_DIR"
fi

echo "DIGITAL_OCEAN_TOKEN=" > "$TOKEN_FILE"

echo "Installing blocklist script to $DIR_BIN/digital-ocean-dns-update.sh..."
cp ./bin/digital-ocean-dns-update.sh "$DIR_BIN/digital-ocean-dns-update.sh"

echo "Setting executable permissions on $DIR_BIN/digital-ocean-dns-update.sh..."
chmod +x "$DIR_BIN/digital-ocean-dns-update.sh"

echo "Installing systemd service /etc/systemd/system/digital-ocean-dns-update.service..."
systemctl disable digital-ocean-dns-update.service 2> /dev/null || true
systemctl disable digital-ocean-dns-update.timer 2> /dev/null || true
cp ./systemd/digital-ocean-dns-update.service /etc/systemd/system/digital-ocean-dns-update.service
cp ./systemd/digital-ocean-dns-update.timer /etc/systemd/system/digital-ocean-dns-update.timer
systemctl daemon-reload
systemctl enable digital-ocean-dns-update.service

echo "Installation complete! Please edit $TOKEN_FILE to add your Digital Ocean API token."
# Enable if you don't restart your system daily
#systemctl enable digital-ocean-dns-update.timer
