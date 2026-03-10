#!/usr/bin/env bash
source /usr/local/lib/kira-router/error-hander.sh
enable_strict_mode

source /usr/local/lib/kira-router/common.lib.sh
source /etc/kira-router/ddns/hetzner/token.sh

HZ_ZONE_ID="kira.rip"

MY_IP_V4=$(get_ipv4_addr wan)
MY_IP_V6=$(get_ipv6_addr wan)

echo "My IPv4 is $MY_IP_V4"
echo "My IPv6 is $MY_IP_V6"

# Usage: get_hz_record <name> <type>
# Fetches the current record value from Hetzner DNS
get_hz_record() {
  local HZ_NAME="$1"
  local HZ_TYPE="$2"
  curl -S -s \
    -H "Authorization: Bearer $HETZNER_TOKEN" \
    "https://api.hetzner.cloud/v1/zones/$HZ_ZONE_ID/rrsets/$HZ_NAME/$HZ_TYPE" \
    | jq -r '.rrset.records[0].value // empty'
}

# Usage: set_name_my_ipv4 <name>
# Sets the A record for the given name to MY_IP_V4, only if it differs
# Example: set_name_my_ipv4 "home"
set_name_my_ipv4() {
  local HZ_NAME="$1"
  local current
  current=$(get_hz_record "$HZ_NAME" "A")
  if [ "$current" = "$MY_IP_V4" ]; then
    echo "A record for $HZ_NAME is already $MY_IP_V4, skipping update"
    return
  fi
  echo "Updating A record for $HZ_NAME: $current -> $MY_IP_V4"
  curl -S -s \
    -X POST \
    -H "Authorization: Bearer $HETZNER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"records":[{"value":"'"$MY_IP_V4"'","comment":"Updated via API '"$(date)"'"}]}' \
    "https://api.hetzner.cloud/v1/zones/$HZ_ZONE_ID/rrsets/$HZ_NAME/A/actions/set_records"
}

# Usage: set_name_my_ipv6 <name>
# Sets the AAAA record for the given name to MY_IP_V6, only if it differs
# Example: set_name_my_ipv6 "home"
set_name_my_ipv6() {
  local HZ_NAME="$1"
  local current
  current=$(get_hz_record "$HZ_NAME" "AAAA")
  if [ "$current" = "$MY_IP_V6" ]; then
    echo "AAAA record for $HZ_NAME is already $MY_IP_V6, skipping update"
    return
  fi
  echo "Updating AAAA record for $HZ_NAME: $current -> $MY_IP_V6"
  curl -S -s \
    -X POST \
    -H "Authorization: Bearer $HETZNER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"records":[{"value":"'"$MY_IP_V6"'","comment":"Updated via API '"$(date)"'"}]}' \
    "https://api.hetzner.cloud/v1/zones/$HZ_ZONE_ID/rrsets/$HZ_NAME/AAAA/actions/set_records"
}

set_name_my_ipv4 "home"
set_name_my_ipv6 "home"
