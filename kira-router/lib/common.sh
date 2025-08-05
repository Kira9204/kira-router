#!/usr/bin/env bash
#
# By: Erik Welander (erik.welander@hotmail.com) https://github.com/Kira9204
# Kira Router - A complete IPv4 and IPv6 router solution based on systemd-networkd, nftables and dnsmasq.
# This script contains common functions used across various scripts in the router setup.
#

# Exits the script if one of the provided commands are not available
# Example: fail_if_not_installed ip nft
fail_if_not_installed() {
  # Loop over all arguments passed to the function
  for cmd in "$@"; do
    if ! command -v "$cmd" > /dev/null 2>&1; then
      echo "Could not find \"$cmd\" command. Exiting..."
      return 1
    fi
  done
}

# Selects the first global scope IPv4 address from the given interface name
# Example: get_global_ipv4_addr wan
get_global_ipv4_addr() {
  if [ $# -lt 1 ]; then
    echo "Error: get_global_ipv4_addr: This function requires at least one argument."
    return 1
  fi
  ip -4 addr show $1 | grep 'global' | awk '{ print $2 }' | cut -f1 -d'/' | head -n 1
}

# Selects the first global scope IPv6 address from the given interface name
# Example: get_global_ipv6_addr wan
get_global_ipv6_addr() {
  if [ $# -lt 1 ]; then
    echo "Error: get_global_ipv6_addr: This function requires at least one argument."
    return 1
  fi
  ip -6 addr show $1 | grep 'global' | awk '{ print $2 }' | cut -f1 -d'/' | head -n 1
}

# Selects the first link-local scope IPv6 address from the given interface name
# Example: get_link_local_ipv6_addr wan
get_link_local_ipv6_addr() {
  if [ $# -lt 1 ]; then
    echo "Error: get_link_local_ipv6_addr: This function requires at least one argument."
    exit 1
  fi
  ip -6 addr show $1 | grep 'link' | awk '{ print $2 }' | cut -f1 -d'/' | head -n 1
}

# Returns a substring truncated at the first slash characcter
# Example:
# ip_address=$(split_at_slash "172.28.80.102/32")
# echo $ip_address
split_at_slash() {
  if [ $# -lt 1 ]; then
    echo "Error: split_string_at_slash: This function requires at least one argument."
    exit 1
  fi
  echo "${1%%/*}"
}

# Will forever ping the given destination address until a response is given
# Example: ping_until_successful 1.1.1.1
ping_until_successful() {
  if [ $# -lt 1 ]; then
    echo "Error: ping_until_successful: This function requires at least one argument."
    exit 1
  fi
  echo "Ping: $1..."
  ping -c 1 $1 > /dev/null 2>&1
  while [ $? -ne 0 ]; do
    echo "Ping failed. Retrying $1 in 1 sec..."
    sleep 1
    ping -c 1 $1 > /dev/null 2>&1
  done
  echo "Ping to $1 successful!"
}

fail_if_not_installed ip
