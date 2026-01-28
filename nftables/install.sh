#!/usr/bin/env bash
set -euo pipefail
# DEBUG mode - Prints every command being executed
#set -x
source ./lib/common.lib.sh
verify_root
fail_if_not_installed ip nft ipcalc systemctl

DIR_CONF="/etc/kira-router/nftables"
DIR_LIB="/usr/local/lib/kira-router"
DIR_BIN="/usr/local/bin"
DIR_SYSTEMD="/etc/systemd/system"

print_info "Installing configurations at $DIR_CONF..."
if [ ! -d "$DIR_CONF" ]; then
  mkdir -p "$DIR_CONF"
fi
cp ./conf/*.sh "$DIR_CONF"

print_info "Installing library at $DIR_LIB..."
if [ ! -d "$DIR_LIB" ]; then
  mkdir -p "$DIR_LIB"
fi
cp ./lib/common.lib.sh "$DIR_LIB"

print_info "Installing main script at $DIR_BIN/kira-router.sh..."
cp ./bin/kira-router.sh "$DIR_BIN"

print_info "Setting executable permissions on $DIR_BIN/kira-router.sh..."
chmod +x "$DIR_BIN/kira-router.sh"

print_info "Installing and enabling systemd service $DIR_SYSTEMD/kira-router.service..."
systemctl stop kira-router.service 2> /dev/null || true
systemctl disable kira-router.service 2> /dev/null || true
cp ./systemd/kira-router.service "$DIR_SYSTEMD"
systemctl daemon-reload
systemctl enable kira-router.service
print_info "To start the service now, run: systemctl start kira-router.service"

print_info "Installation complete!"
print_info "You can run the main script using: kira-router [start|stop]"
