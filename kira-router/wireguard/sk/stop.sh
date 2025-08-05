#!/usr/bin/env bash
# Ignore if a command returns a non-0
set +e
# Import functions into our script
import_arr=("../../lib/common.sh" "./env.sh")
for to_import in "${import_arr[@]}"; do
  if [[ ! -f "$to_import" ]]; then
    echo "Could not find $to_import file to import!" >&2
    exit 1
  fi
  source "$to_import"
done
fail_if_not_installed wg

echo "Removing old routes and devices..."

ip -4 route del $ROUTE_DOS
ip -4 route del $ROUTE_NEO
ip -4 route del $ROUTE_TB

# Remove the interface
ip link del dev $IVPN
