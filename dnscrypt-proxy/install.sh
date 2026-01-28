#!/usr/bin/env bash
set -euo pipefail
# DEBUG mode - Prints every command being executed
#set -x
source /usr/local/lib/kira-router/common.lib.sh
verify_root
fail_if_not_installed dnscrypt-proxy

DIR_CONF="/etc/dnscrypt-proxy"

echo "Replacing dnscrypt-proxy configurations..."
cp ./conf/dnscrypt-proxy.toml "$DIR_CONF"

echo "Enabling dnscrypt-proxy service..."
systemctl enable dnscrypt-proxy
systemctl restart dnscrypt-proxy
echo "Installation complete!"
