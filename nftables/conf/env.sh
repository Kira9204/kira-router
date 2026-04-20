#!/usr/bin/env bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || {
  echo "This file must be sourced, not executed" 1>&2
  exit 1
}

# This script should only be triggered by system-wait-online.service.
# In case the network is still not configured properly, we will wait and retry
# every second until the maximum number of attempts is reached.
WAIT_MAX_ATTEMPTS=10

###### Internal LAN settings ######
## IPv4 configuration
GLOBAL_ILAN_NAME=lan
GLOBAL_ILAN_IPV4_ENABLED="true"
GLOBAL_ILAN_IPV4_ADDR="10.0.6.1"
GLOBAL_ILAN_IPV4_SUB="24"
GLOBAL_ILAN_IPV4_CDIR="$GLOBAL_ILAN_IPV4_ADDR/$GLOBAL_ILAN_IPV4_SUB"

## IPv6 configuration
GLOBAL_ILAN_IPV6_ENABLED="true"
# Set to "auto" to get the first global IPv6 address of the interface.
# Otherwise set to a IPv6 ULA address like fde5:7dda:9d44::1
GLOBAL_ILAN_IPV6_ADDR="auto"
# ISPs will typically assign /56 or /60 prefixes for home users via DHCPv6-PD.
# From there you can subnet to /64 for your LAN.
# You should typically leave this at 64 for SLAAC to work.
GLOBAL_ILAN_IPV6_SUB="64"
# If the address and subnet are set to auto, this will be automatically resolved.
GLOBAL_ILAN_IPV6_CDIR="$GLOBAL_ILAN_IPV6_ADDR/$GLOBAL_ILAN_IPV6_SUB"

###### External WAN settings ######
## IPv4 configuration
GLOBAL_IWAN_NAME=wan
GLOBAL_IWAN_IPV4_ENABLED="true"
# Set to "auto" to get the first global IPv4 address of the interface.
# Otherwise set to a static IPv4 address.
GLOBAL_IWAN_IPV4_ADDR="auto"
# Set to "auto" to get the subnet mask of the interface.
GLOBAL_IWAN_IPV4_SUB="auto"
# If the address and subnet are set to auto, this will be automatically resolved.
GLOBAL_IWAN_IPV4_CDIR="$GLOBAL_IWAN_IPV4_ADDR/$GLOBAL_IWAN_IPV4_SUB"

## IPv6 configuration
GLOBAL_IWAN_IPV6_ENABLED="true"
# Set to "auto" to get the first global IPv6 address of the interface.
# Otherwise set your static IPv6 address.
GLOBAL_IWAN_IPV6_ADDR="auto"
# Needs to be 64 for SLAAC to work properly in most cases.
GLOBAL_IWAN_IPV6_SUB="64"
# If the address and subnet are set to auto, this will be automatically resolved.
GLOBAL_IWAN_IPV6_CDIR="$GLOBAL_IWAN_IPV6_ADDR/$GLOBAL_IWAN_IPV6_SUB"

###### Internet Gateway Settings ######
# 1. "NAT" to enable firewalled IPv4 gateway mode (NAT)
# 2. "NONE" to disable IPv4 gateway mode.
GLOBAL_INTERNET_GATEWAY_MODE_IPV4="NAT"

# 1. "FORWARD" to enable firewalled IPv6 forwarding mode (no NAT) (recommended)"
# 2. "NAT" to enable IPv6 gateway mode with NAT66. (Not recommended)"
# 3. "NONE" to do nothing.
# It is recommended to use FORWARD mode if your ISP provides native IPv6 connectivity via DHCPv6-PD.
# For local addressing, use ULA addresses (fde5:7dda:9d44::/48)
GLOBAL_INTERNET_GATEWAY_MODE_IPV6="FORWARD"

# IPv6 Port Forwarding Mode
# 1. FORWARD: This mode sets up simple forwarding rules that allow direct access to the destination host's global IPv6 address.
#    This is the most straightforward and "IPv6 native" way to do port forwarding, since all hosts have public IPv6 addresses
#    and there is typically no need for address translation.
# 2. FORWARD_NAT: This mode sets up both forwarding and NAT rules, allowing access to the destination host both via its
#    own IPv6 address, and via the WAN interface's IPv6 address and the forwarded port.
# 3. NAT: This mode sets up only NAT rules, allowing access to the destination host via the WAN interface's IPv6 address and the forwarded port.
#    Only use this mode if you are also doing NAT66, where all of your clients use local IPv6 addresses and the router performs NAT via its WAN IPv6 address.
GLOBAL_IPV6_PORT_FORWARDING_MODE="FORWARD"
