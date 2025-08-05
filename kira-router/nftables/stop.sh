#!/usr/bin/env bash
#
# By: Erik Welander (erik.welander@hotmail.com) https://github.com/Kira9204
# Kira Router - A complete IPv4 and IPv6 router solution based on systemd-networkd, nftables and dnsmasq.
# This script clears all nftables rules.
#

# Exit if a non-0 is returned
set -e

#### Import Nftables utilities ####
import_arr=("../lib/common.sh" "./lib.sh")
for to_import in "${import_arr[@]}"; do
  if [[ ! -f "$to_import" ]]; then
    echo "Could not find $to_import file to import!" >&2
    exit 1
  fi
  source "$to_import"
done
fail_if_not_installed ip nft

nft_clear_all
