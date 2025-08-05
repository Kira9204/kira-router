#!/usr/bin/env bash
# Exit if a non-0 is returned
set -e
# Import functions into our script
import_arr=("../../lib/common.sh" "./env.sh")
for to_import in "${import_arr[@]}"; do
  if [[ ! -f "$to_import" ]]; then
    echo "Could not find $to_import file to import!" >&2
    exit 1
  fi
  source "$to_import"
done
fail_if_not_installed ip wg

# Ignore if stop command fails (device does not exist for example)
set +e
./stop.sh
#set -e

echo "Setting up interface and routes..."

# Add interface
ip link add dev $IVPN type wireguard
wg setconf $IVPN wg.conf
ip link set $IVPN up

# Assign VPN address
ip -4 address add $IVPN_IPv4/30 dev $IVPN

# Failed status codes when pinging is expected
set +e
ping_until_successful $IVPN_IPv4

echo Wireguard OVPN connection successful!
