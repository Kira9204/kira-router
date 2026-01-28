#!/usr/bin/env bash
set -euo pipefail
source /usr/local/lib/kira-router/common.lib.sh
source /etc/kira-router/ddns/hetzner/token.sh

HZ_ZONE_ID="kira.rip"

MY_IP_V4=$(get_ipv4_addr wan)
MY_IP_V6=$(get_ipv6_addr wan)

echo "My IPv4 is $MY_IP_V4"
echo "My IPv6 is $MY_IP_V6"

# Usage: set_name_my_ipv4 <name>
# Sets the A record for the given name to MY_IP_V4
# Example: set_name_my_ipv4 "home"
set_name_my_ipv4() {
  local HZ_NAME="$1"
  curl \
    -X POST \
    -H "Authorization: Bearer $HETZNER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"records":[{"value":"'"$MY_IP_V4"'","comment":"Updated via API '"$(date)"'"}]}' \
    "https://api.hetzner.cloud/v1/zones/$HZ_ZONE_ID/rrsets/$HZ_NAME/A/actions/set_records"
}

# Usage: set_name_my_ipv6 <name>
# Sets the AAAA record for the given name to MY_IP_V6
# Example: set_name_my_ipv6 "home"
set_name_my_ipv6() {
  local HZ_NAME="$1"
  curl \
    -X POST \
    -H "Authorization: Bearer $HETZNER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"records":[{"value":"'"$MY_IP_V6"'","comment":"Updated via API '"$(date)"'"}]}' \
    "https://api.hetzner.cloud/v1/zones/$HZ_ZONE_ID/rrsets/$HZ_NAME/AAAA/actions/set_records"
}

set_name_my_ipv4 "home"
set_name_my_ipv6 "home"
