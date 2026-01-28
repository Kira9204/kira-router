#!/usr/bin/env bash
set -euo pipefail
# DEBUG mode - Prints every command being executed
#set -x
source /usr/local/lib/kira-router/common.lib.sh
verify_root
fail_if_not_installed sshd

DIR_CONF_LOCAL="./conf/sshd_config.d"
DIR_CONF="/etc/ssh/sshd_config.d"
print_info "Installing configurations at $DIR_CONF..."
if [ ! -d "$DIR_CONF" ]; then
  mkdir -p "$DIR_CONF"
fi
cp "$DIR_CONF_LOCAL/"*.conf "$DIR_CONF"

print_info "Installation complete!"
