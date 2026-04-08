#!/usr/bin/env bash
DIR_LIB="/usr/local/lib/kira-router"
DIR_CONF="/etc/kira-router/ddns/hetzner"
source "$DIR_LIB/error-hander.sh"
enable_strict_mode

source "$DIR_LIB/common.lib.sh"
source "$DIR_CONF/conf.sh"

if [ "$MY_IP_V4" == "auto" ]; then
  print_info "Automatically detecting public IPv4 address..."
  MY_IP_V4=$(get_ipv4_addr wan)
fi

if [ "$MY_IP_V6" == "auto" ]; then
  print_info "Automatically detecting public IPv6 address..."
  MY_IP_V6=$(get_ipv6_addr wan)
fi

print_info "My IPv4 is $MY_IP_V4"
print_info "My IPv6 is $MY_IP_V6"

# Usage: get_hz_record <zone> <name> <type>
# Fetches the current record value from Hetzner DNS
get_hz_record() {
  local HZ_ZONE="$1"
  local HZ_NAME="$2"
  local HZ_TYPE="$3"
  curl -S -s \
    -H "Authorization: Bearer $HZ_TOKEN" \
    "https://api.hetzner.cloud/v1/zones/$HZ_ZONE/rrsets/$HZ_NAME/$HZ_TYPE" \
    | jq -r '.rrset.records[0].value // empty'
}

# Usage: update_ipv4_name <zone> <name>
# Sets the A record for the given name to MY_IP_V4, only if it differs
# Example: update_ipv4_name "kira.rip" "home"
update_ipv4_name() {
  local HZ_ZONE="$1"
  local HZ_NAME="$2"
  local current=$(get_hz_record "$HZ_ZONE" "$HZ_NAME" "A")
  if [ "$current" = "$MY_IP_V4" ]; then
    print_info "A record for $HZ_NAME is already $MY_IP_V4, skipping update"
    return
  fi
  print_info "Updating A record for $HZ_NAME: $current -> $MY_IP_V4"
  curl -S -s \
    -X POST \
    -H "Authorization: Bearer $HZ_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"records":[{"value":"'"$MY_IP_V4"'","comment":"Updated via API '"$(date +%Y-%m-%d--%H-%M-%S)"'"}]}' \
    "https://api.hetzner.cloud/v1/zones/$HZ_ZONE/rrsets/$HZ_NAME/A/actions/set_records"
}

# Usage: update_ipv6_name <zone> <name>
# Sets the AAAA record for the given name to MY_IP_V6, only if it differs
# Example: update_ipv6_name "kira.rip" "home"
update_ipv6_name() {
  local HZ_ZONE="$1"
  local HZ_NAME="$2"
  local current
  current=$(get_hz_record "$HZ_ZONE" "$HZ_NAME" "AAAA")
  if [ "$current" = "$MY_IP_V6" ]; then
    print_info "AAAA record for $HZ_NAME is already $MY_IP_V6, skipping update"
    return
  fi
  print_info "Updating AAAA record for $HZ_NAME: $current -> $MY_IP_V6"
  curl -S -s \
    -X POST \
    -H "Authorization: Bearer $HZ_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"records":[{"value":"'"$MY_IP_V6"'","comment":"Updated via API '"$(date +%Y-%m-%d--%H-%M-%S)"'"}]}' \
    "https://api.hetzner.cloud/v1/zones/$HZ_ZONE/rrsets/$HZ_NAME/AAAA/actions/set_records"
}

for domain in "${HZ_ZONES[@]}"; do
  for name in "${HZ_IPV4_NAMES[@]}"; do
    update_ipv4_name "$domain" "$name"
  done
  for name in "${HZ_IPV6_NAMES[@]}"; do
    update_ipv6_name "$domain" "$name"
  done
done
