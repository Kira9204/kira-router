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
# Set to "NAT" to enable firewalled IPv4 gateway mode (NAT)
# Set to "NONE" to disable IPv4 gateway mode.
GLOBAL_INTERNET_GATEWAY_MODE_IPV4="NAT"

# Set to "FORWARD" to enable firewalled IPv6 forwarding mode (no NAT) (recommended)"
# Set to "NAT" to enable IPv6 gateway mode with NAT66. (Not recommended)"
# Set to "NONE" to do nothing.
# It is recommended to use FORWARD mode if your ISP provides native IPv6 connectivity via DHCPv6-PD.
# For local addressing, use ULA addresses (fde5:7dda:9d44::/48)
GLOBAL_INTERNET_GATEWAY_MODE_IPV6="FORWARD"
