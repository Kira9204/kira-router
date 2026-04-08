#!/usr/bin/env bash
DIR_LIB="/usr/local/lib/kira-router"
DIR_CONF="/etc/kira-router/ddns/digital-occean"
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

# Usage: print_do_records <domain> | jq
# Example: print_do_records "kira.rip" | jq '.domain_records[] | select(.name == "@" and .type == "A")'
print_do_records() {
  local DO_DOMAIN="$1"
  curl -S -s \
    -H "Authorization: Bearer $DO_TOKEN" \
    -H "Content-Type: application/json" \
    "https://api.digitalocean.com/v2/domains/$DO_DOMAIN/records"
}

# Usage: get_do_record <domain> <name> <type>
# Returns "id:current_value" for the first matching record, or empty if not found
# Example: get_do_record "kira.rip" "@" "A" -> "12345678:1.2.3.4"
get_do_record() {
  local DO_DOMAIN="$1"
  local DO_NAME="$2"
  local DO_TYPE="$3"
  print_do_records "$DO_DOMAIN" \
    | jq -r '.domain_records[] | select(.name == "'"$DO_NAME"'" and .type == "'"$DO_TYPE"'") | "\(.id):\(.data)"' \
    | head -n1
}

# Usage: update_ipv4_name <domain> <name>
# Sets the A record for the given name to MY_IP_V4 only if it differs
# Example: update_ipv4_name "kira.rip" "@"
update_ipv4_name() {
  local DO_DOMAIN="$1"
  local DO_NAME="$2"
  local record=$(get_do_record "$DO_DOMAIN" "$DO_NAME" "A")
  if [ -z "$record" ]; then
    print_info "No A record found for $DO_DOMAIN.$DO_NAME, skipping"
    return
  fi
  local record_id="${record%%:*}"
  local current="${record#*:}"
  if [ "$current" = "$MY_IP_V4" ]; then
    print_info "A record for $DO_DOMAIN.$DO_NAME is already $MY_IP_V4, skipping update"
    return
  fi

  print_info "Updating A record for $DO_DOMAIN.$DO_NAME: $current -> $MY_IP_V4"
  local response
  response=$(curl -S -s -X PUT \
    -H "Authorization: Bearer $DO_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"data\":\"$MY_IP_V4\"}" \
    "https://api.digitalocean.com/v2/domains/$DO_DOMAIN/records/$record_id")

  if echo "$response" | jq -e '.message' > /dev/null 2>&1; then
    print_error "Error updating A record for $DO_DOMAIN.$DO_NAME: $response"
  fi
}

# Usage: update_ipv6_name <domain> <name>
# Sets the AAAA record for the given name to MY_IP_V6 only if it differs
# Example: update_ipv6_name "kira.rip" "@"
update_ipv6_name() {
  local DO_DOMAIN="$1"
  local DO_NAME="$2"
  local record=$(get_do_record "$DO_DOMAIN" "$DO_NAME" "AAAA")
  if [ -z "$record" ]; then
    print_info "No AAAA record found for $DO_DOMAIN.$DO_NAME, skipping"
    return
  fi
  local record_id="${record%%:*}"
  local current="${record#*:}"
  if [ "$current" = "$MY_IP_V6" ]; then
    print_info "AAAA record for $DO_DOMAIN.$DO_NAME is already $MY_IP_V6, skipping update"
    return
  fi

  print_info "Updating AAAA record for $DO_DOMAIN.$DO_NAME: $current -> $MY_IP_V6"
  local response
  response=$(curl -S -s -X PUT \
    -H "Authorization: Bearer $DO_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"data\":\"$MY_IP_V6\"}" \
    "https://api.digitalocean.com/v2/domains/$DO_DOMAIN/records/$record_id")

  if echo "$response" | jq -e '.message' > /dev/null 2>&1; then
    print_error "Error updating AAAA record for $DO_DOMAIN.$DO_NAME: $response"
  fi
}

for domain in "${DO_ZONES[@]}"; do
  for name in "${DO_IPV4_NAMES[@]}"; do
    update_ipv4_name "$domain" "$name"
  done
  for name in "${DO_IPV6_NAMES[@]}"; do
    update_ipv6_name "$domain" "$name"
  done
done
