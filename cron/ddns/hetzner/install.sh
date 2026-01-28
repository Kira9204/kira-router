#!/usr/bin/env bash
set -euo pipefail
# DEBUG mode - Prints every command being executed
#set -x
source /usr/local/lib/kira-router/common.lib.sh
verify_root
fail_if_not_installed systemctl curl

DIR_BIN="/usr/local/bin"
DIR_SYSTEMD="/etc/systemd/system"

TOKEN_DIR="/etc/kira-router/ddns/hetzner"
TOKEN_FILE="$TOKEN_DIR/token.sh"
echo "Adding config directory $TOKEN_DIR..."
if [ ! -d "$TOKEN_DIR" ]; then
  mkdir -p "$TOKEN_DIR"
fi
echo "HETZNER_TOKEN=" > "$TOKEN_FILE"

echo "Installing blocklist script to $DIR_BIN/hetzner-dns-update.sh..."
cp ./bin/hetzner-dns-update.sh "$DIR_BIN/hetzner-dns-update.sh"

echo "Setting executable permissions on $DIR_BIN/hetzner-dns-update.sh..."
chmod +x "$DIR_BIN/hetzner-dns-update.sh"

echo "Installing systemd service /etc/systemd/system/hetzner-dns-update.service..."
systemctl disable hetzner-dns-update.service 2> /dev/null || true
systemctl disable hetzner-dns-update.timer 2> /dev/null || true
cp ./systemd/hetzner-dns-update.service /etc/systemd/system/hetzner-dns-update.service
cp ./systemd/hetzner-dns-update.timer /etc/systemd/system/hetzner-dns-update.timer
systemctl daemon-reload
systemctl enable hetzner-dns-update.service

echo "Installation complete! Please edit $TOKEN_FILE to add your Hetzner API token."
# Enable if you don't restart your system daily
#systemctl enable hetzner-dns-update.timer 2>/dev/null || true
