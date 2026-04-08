#!/usr/bin/env bash
set -euo pipefail
# DEBUG mode - Prints every command being executed
#set -x
source /usr/local/lib/kira-router/common.lib.sh
verify_root
fail_if_not_installed systemctl curl

DIR_BIN="/usr/local/bin"
DIR_SYSTEMD="/etc/systemd/system"

DIR_CONF="/etc/kira-router/ddns/hetzner"
echo "Adding config directory $DIR_CONF..."
if [ ! -d "$DIR_CONF" ]; then
  mkdir -p "$DIR_CONF"
fi

echo "Installing default config to $DIR_CONF"
cp ./conf/conf.sh "$DIR_CONF/conf.sh"

echo "Installing script to $DIR_BIN/hetzner-dns-update.sh..."
cp ./bin/hetzner-dns-update.sh "$DIR_BIN/hetzner-dns-update.sh"

echo "Setting executable permissions on $DIR_BIN/hetzner-dns-update.sh..."
chmod +x "$DIR_BIN/hetzner-dns-update.sh"

echo "Installing systemd service $DIR_SYSTEMD/hetzner-dns-update.service..."
systemctl disable hetzner-dns-update.service 2> /dev/null || true
systemctl disable hetzner-dns-update.timer 2> /dev/null || true
cp ./systemd/hetzner-dns-update.service "$DIR_SYSTEMD/hetzner-dns-update.service"
cp ./systemd/hetzner-dns-update.timer "$DIR_SYSTEMD/hetzner-dns-update.timer"
systemctl daemon-reload
systemctl enable hetzner-dns-update.service

echo "Installation complete! Please edit $DIR_CONF/conf.sh to add add your configuration"
# Enable if you don't restart your system daily
#systemctl enable hetzner-dns-update.timer 2>/dev/null || true
