#!/usr/bin/env bash
# Exit if a non-0 is returned
set -e
# Import functions into our script
import_arr=("../../lib/common.sh" "./env.sh")
for to_import in "$import_arr[@]"; do
  if [[ ! -f "$to_import" ]]; then
    echo "Could not find $to_import file to import!" >&2
    exit 1
  fi
  source "$to_import"
done
fail_if_not_installed ip wg

# Usage: print_records <domain> | jq
print-records() {
  curl -X GET -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    "https://api.digitalocean.com/v2/domains/$1/records"
}

# Usage: update_record <domain> <record_id> <new value> | jq
update-record() {
  curl -X PUT -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{\"data\":\"$3\"}" \
    "https://api.digitalocean.com/v2/domains/$1/records/$2"

}

local IPv4=$(get_global_ipv4_addr wan)
local IPv6=$(get_global_ipv6_addr wan)
local log=/root/kira-router/cron/dns/log.txt

echo "My IPv4 is $IPv4" > $log
echo "My IPv6 is $IPv6" >> $log

#print-records kira.rip | jq
echo "" >> $log
update-record domain id $IPv4 >> $log
echo "" >> $log
update-record domain id $IPv6 >> $log
echo "" >> $log
