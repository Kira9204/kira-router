#!/usr/bin/env bash
set -euo pipefail
# DEBUG mode - Prints every command being executed
#set -x

source /usr/local/lib/kira-router/common.lib.sh

WG_CONF="/etc/wireguard/sk/wg.conf"

IVPN_NAME=wg_sk
IVPN_IPV4_ADDR=169.254.0.4
IVPN_IPV4_SUB=26
IVPN_IPV4_CDIR="$IVPN_IPV4_ADDR/$IVPN_IPV4_SUB"
ILAN_IPV4_ADDR=$(get_ipv4_addr lan)

ROUTE_TB="10.0.4.0/24 via 169.254.0.3 src $ILAN_IPV4_ADDR"

setup() {
  print_info "Setting up interface and routes..."

  # Add interface
  ip link add dev $IVPN_NAME type wireguard
  wg setconf $IVPN_NAME $WG_CONF
  ip link set $IVPN_NAME up

  # Assign VPN address
  ip -4 address add $IVPN_IPV4_CDIR dev $IVPN_NAME

  # Allow forwarding between interfaces
  nft add rule ip filter input iifname $IVPN_NAME accept
  nft add rule ip filter forward iifname $IVPN_NAME accept
  nft add rule ip filter forward oifname $IVPN_NAME accept

  # Add routes to remote networks
  ip -4 route add $ROUTE_TB

  # Failed status codes when pinging is expected
  set +e
  ping_until_successful $IVPN_IPV4_ADDR
  set -e

  echo Wireguard SK connection successful!
}

teardown() {
  print_info "Removing old routes and devices..."

  set +e
  ip -4 route del $ROUTE_TB

  # Remove the interface
  ip link del dev $IVPN_NAME
  set -e
}

# ===== Main execution controlled by first argument =====
CMD="${1:-start}"
case "$CMD" in
  start)
    teardown
    setup
    ;;
  stop)
    teardown
    ;;
  *)
    print_error "Unknown command: $CMD"
    print_info "Usage: $0 [start|stop]"
    exit 1
    ;;
esac
