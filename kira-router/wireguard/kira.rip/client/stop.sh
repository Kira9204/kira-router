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
fail_if_not_installed ip

echo "Removing interface..."
ip link del dev $IVPN
