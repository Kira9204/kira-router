#!/usr/bin/env bash
set -euo pipefail
# DEBUG mode - Prints every command being executed
#set -x
source /usr/local/lib/kira-router/common.lib.sh

DIR_BLOCKLIST="/etc/unbound/block.d"
FILE_STEVEN_BLACK="$DIR_BLOCKLIST/steven_black.conf"

if [ ! -d "$DIR_BLOCKLIST" ]; then
  mkdir -p "$DIR_BLOCKLIST"
fi

# The big OISD blocklist covers the steven_black list as well.
# I recommend using only one of them.
update_oisd_blocklist() {
  local file_oisd="$DIR_BLOCKLIST/oisd.conf"
  download_and_replace "https://big.oisd.nl/unbound" "$file_oisd"
}

update_oisd_blocklist
systemctl restart unbound.service
