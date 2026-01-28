#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/kira-router/common.lib.sh
source /etc/kira-router/ddns/digital-ocean/token.sh

DOMAIN="kira.rip"

MY_IP_V4=$(get_ipv4_addr wan)
MY_IP_V6=$(get_ipv6_addr wan)

echo "My IPv4 is $MY_IP_V4"
echo "My IPv6 is $MY_IP_V6"

# Usage: print_records | jq
print-records() {
  curl -X GET -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DIGITAL_OCEAN_TOKEN" \
    "https://api.digitalocean.com/v2/domains/$DOMAIN/records"
}

# Usage: update_record <record_id> <new value> | jq
update-record() {
  local record_id="$1"
  local new_value="$2"
  curl -X PUT -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DIGITAL_OCEAN_TOKEN" \
    -d "{\"data\":\"$new_value\"}" \
    "https://api.digitalocean.com/v2/domains/$DOMAIN/records/$record_id"
}

#print-records $DOMAIN | jq
update-record 111111111 $MY_IP_V4
update-record 222222222 $MY_IP_V6
