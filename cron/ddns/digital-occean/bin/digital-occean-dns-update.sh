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
  curl -S -s -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DIGITAL_OCEAN_TOKEN" \
    "https://api.digitalocean.com/v2/domains/$DOMAIN/records"
}

# Usage: get_record_value <record_id>
# Fetches the current record value from Digital Ocean DNS
get-record-value() {
  local record_id="$1"
  curl -S -s -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DIGITAL_OCEAN_TOKEN" \
    "https://api.digitalocean.com/v2/domains/$DOMAIN/records/$record_id" \
    | jq -r '.domain_record.data // empty'
}

# Usage: update_record <record_id> <new value> | jq
# Only updates if the current value differs from the new value
update-record() {
  local record_id="$1"
  local new_value="$2"
  local current
  current=$(get-record-value "$record_id")
  if [ "$current" = "$new_value" ]; then
    echo "Record $record_id is already $new_value, skipping update"
    return
  fi
  echo "Updating record $record_id: $current -> $new_value"
  curl -S -s -X PUT -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DIGITAL_OCEAN_TOKEN" \
    -d "{\"data\":\"$new_value\"}" \
    "https://api.digitalocean.com/v2/domains/$DOMAIN/records/$record_id"
}

#print-records $DOMAIN | jq
update-record 111111111 $MY_IP_V4
update-record 222222222 $MY_IP_V6
