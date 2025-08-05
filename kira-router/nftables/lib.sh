#!/usr/bin/env bash
#
# By: Erik Welander (erik.welander@hotmail.com) https://github.com/Kira9204
# Kira Router - A complete IPv4 and IPv6 router solution based on systemd-networkd, nftables and dnsmasq.
# This library provides functions to manage nftables rules and configurations for a router setup.
#

print_network_config() {
  echo "======== Configuring NFTables with the following interfaces ========"
  echo "==== LAN ===="
  echo "Interface name: $LAN"
  echo "IPv4 address: $LAN_IPv4"
  echo "IPv6 address: $LAN_IPv6"
  echo "IPv6 ULA address: $LAN_IPv6_ULA"
  echo
  echo "==== WAN ===="
  echo "Interface name: $WAN"
  echo "IPv4 address: $WAN_IPv4"
  echo "IPv6 address: $WAN_IPv6"
  echo
  echo
}

# Clears all nftables rules and tables, leaving a blank confiruation.
# The entire rule set can be printed with "nft list tables".
nft_clear_all() {
  echo "Clearing all NFTables..."
  nft list tables \
    | while read table; do
      nft delete $table
    done
}

# This configures nftables with sane defaults for a router setup
nft_setup_defaults() {
  nft_clear_all
  echo "Applying NFTables defaults..."

  #### IPv4 configuration ####
  # Set up tables and default policies
  nft add table ip filter
  nft add chain ip filter input '{ type filter hook input priority 0; policy drop; }'
  nft add chain ip filter forward '{ type filter hook forward priority 0; policy drop; }'
  nft add chain ip filter output '{ type filter hook output priority 0; policy accept; }'

  # Set up NAT tables
  nft add table ip nat
  nft add chain ip nat prerouting '{ type nat hook prerouting priority -100; policy accept; }'
  nft add chain ip nat postrouting '{ type nat hook postrouting priority 100; policy accept; }'

  # Always allow localhost
  nft add rule ip filter input iifname lo accept

  # Allow established connections, sessions that YOU created from within your LAN
  nft add rule ip filter input ct state related,established accept
  nft add rule ip filter forward ct state related,established accept

  # Allow DHCPv4 traffic
  nft add rule ip filter input udp sport 67-68 udp dport 67-68 accept

  # Allow ICMP traffic.
  # This is not required for IPv4, but useful when debugging.
  nft add rule ip filter input meta l4proto icmp accept

  #### IPv6 configuration ####
  nft add table ip6 filter
  nft add chain ip6 filter input '{ type filter hook input priority 0; policy drop; }'
  nft add chain ip6 filter forward '{ type filter hook forward priority 0; policy drop; }'
  nft add chain ip6 filter output '{ type filter hook output priority 0; policy accept; }'

  # Set up NAT tables.
  # Typically IPv6 is not NATed, since all clients have public IP addresses we simply FORWARD
  # traffic based upon the same session rules that we apply to IPv4.
  # That is established connections, sessions that YOU created from within your LAN.
  #
  # There are cases where translating IPv6 addresses are useful however.
  # One example being forwaring HTTP traffic on port 80 from your WAN IPv6 address to an IPv6 address on the LAN side.
  # Both clients have public IPs, so a simple traffic forwarding would suffice, but it's convinient
  # And follows a traditional IPv4 NAT style configuration should you prefer it.
  nft add table ip6 nat
  nft add chain ip6 nat prerouting '{ type nat hook prerouting priority -100; policy accept; }'
  nft add chain ip6 nat postrouting '{ type nat hook postrouting priority 100; policy accept; }'

  # Always allow localhost
  nft add rule ip6 filter input iifname lo accept

  # Allow established connections, sessions that YOU created from within your LAN
  nft add rule ip6 filter input ct state related,established accept
  nft add rule ip6 filter forward ct state related,established accept

  # The following are required for IPv6 to function correctly
  nft add rule ip6 filter input ip6 saddr fe80::/10 accept # Link-local addresses
  nft add rule ip6 filter input ip6 saddr ff00::/8 accept  # Multicast addresses
  nft add rule ip6 filter input meta l4proto ipv6-icmp accept

  # Allow DHCPv6 traffic
  nft add rule ip6 filter input udp sport 546-547 udp dport 546-547 accept

  #### Allow all requests that originates from our LAN ####
  #### This includes both the input and forward chains

  #### IPv4 configuration ####
  nft add rule ip filter input iifname $LAN accept
  nft add rule ip filter forward iifname $LAN accept
  # Allow all forwards that have a DNAT destination
  nft add rule ip filter forward ct status dnat accept

  #### IPv6 configuration ####
  nft add rule ip6 filter input iifname $LAN accept
  nft add rule ip6 filter forward iifname $LAN accept
  # Allow all forwards that have a DNAT destination
  nft add rule ip6 filter forward ct status dnat accept
}

# This allows all traffic from the given input interfaces
# Example allow_interfaces lan vpn
allow_interfaces() {
  if [ $# -lt 1 ]; then
    echo "Error: allow_interface: This function requires at least one argument." >&2
    return 1
  fi

  for interface in "$@"; do
    # If the interface variable is empty, skip it
    if [[ -z "$interface" ]]; then
      continue
    fi

    echo "Allowing all traffic from interface $interface..."
    #### IPv4 ####
    nft add rule ip filter input iifname "$interface" accept
    nft add rule ip filter forward iifname "$interface" accept
    #### IPv6 ####
    nft add rule ip6 filter input iifname "$interface" accept
    nft add rule ip6 filter forward iifname "$interface" accept
  done
}

# Performs IPv4 masquerading (NAT/PAT).
# Arguments:
# $1 LAN_ADDR the source ip subnet (example: 10.0.6.0)
# $2 LAN_SUB the number of subnet bits (example: 24)
# $3 The output interface. This is typically the WAN interface
#
# Example: masquerade_ipv4 10.0.6.0 24 wan
masquerade_ipv4() {
  if [ $# -lt 3 ]; then
    echo "Error: masquerade_ipv4: This function requires a LAN_ADDR, LAN_SUB and an output interface." >&2
    echo "Example: masquerade_ipv4 10.0.6.0 24 wan" >&2
    return 1
  fi
  echo "Masquerading IPv4 traffic from subnet $1/$2 to output interface $3..."
  nft add rule ip nat postrouting ip saddr $1/$2 oifname $3 masquerade
}

# Maskquerade (NAT) the following IPv6 ULA subnet.
# Since everyone has a public IPv6 address thru IPv6 prefix delegateion, there will typically never be a need for address translations,
# traffic is normally FORWARDED between the interfaces based upon the connection session state.
# Use this if you for whatever reason are going for a ULA network to mirror an IPv4 nat
# Arguments:
# $1 LAN_ADDR the source ip subnet (example: fd5e:e3ee:4154::/48)
# $2 The output interface. This is typically the WAN interface
# Example: masquerade_ipv6 fd5e:e3ee:4154::/48 wan
masquerade_ipv6() {
  if [ $# -lt 3 ]; then
    echo "Error: masquerade_ipv6: This function requires a LAN_IPv6_ULA_ADDR, LAN_IPv6_ULA_SUB and an output interface." >&2
    echo "Example: masquerade_ipv6 fd5e:e3ee:4154:: 48 wan" >&2
    return 1
  fi
  echo "Masquerading IPv6 traffic from subnet $1/$2 to output interface $3..."
  nft add rule ip6 nat postrouting ip6 saddr $1/$2 oifname $3 masquerade
}

# Opens a specificed protocol port, or port rage on the router given the port_obj name.
# The port can either be a single digit, or a port range.
#
# Use this if you want SSH access from the internet, or are running a wireguard service on the router.
#
# Note that this only opens the port on the ROUTER, if you want to forward a port
# to a host behind the router use forward() instead.
#
# Examples:
# http=(tcp 80 true)
# some-service=(tcp 22-23 true)
open() {
  if [ $# -lt 1 ]; then
    echo "Error: open: This function requires a port object name argument" >&2
    echo "Examples:" >&2
    echo "http=(tcp 80 true)" >&2
    echo "some-service=(tcp 22-23 true)" >&2
    echo "open http" >&2
    echo "open some-service" >&2
    return 1
  fi

  local port_obj=$1
  # Is this rule active?
  local -n port_array_ref=$port_obj
  local enabled=${port_array_ref[2]}
  if [[ "$enabled" != "true" ]]; then
    echo "Ignoring open $port_obj since the port is disabled..."
    return 0
  fi

  local dst_protocol=${port_array_ref[0]}
  local dst_port=${port_array_ref[1]}
  echo "Opening up port $port_obj $dst_protocol $dst_port..."

  nft add rule ip filter input ip daddr $WAN_IPv4 $dst_protocol dport $dst_port accept
  if [[ -n "$WAN_IPv6" ]]; then
    nft add rule ip6 filter input ip6 daddr $WAN_IPv6 $dst_protocol dport $dst_port accept
  fi
}

# Performs port forwarding for the given service.
# A common example is to expose a web server behind the router to the internet.
# Supports both IPv4 and IPv6.
#
# For IPv4, this sets up DNAT.
# For IPv6, only a simple forward is needed, but we set up an SNAT rule
# from the router to the server as well to make DNS easier.
# This way you can use your routers public IPv6 address and forward the traffic
# To a public IPv6 address behind it.
#
# Example usage:
# server=("10.0.6.2" "<Optional public-ipv6-address>")
# http=(tcp 80 true)
# some-service=(tcp 22-23 true)
# ssh=(tcp 20000 true)
#
# forward server http
# forward server some-service
# forward server some-service <internal port>
# forward server ssh 22
#
forward() {
  if [ $# -lt 2 ]; then
    echo "Error: forward: This function requires a host variable name and service variable name." >&2
    echo "Example: forward server http" >&2
    return 1
  fi

  local host_obj=$1
  local port_obj=$2

  # Is this rule active?
  local -n port_array_ref=$port_obj
  local enabled=${port_array_ref[2]}
  if [[ "$enabled" != "true" ]]; then
    echo "Ignoring forward $1 $2 since the port is disabled..."
    return 0
  fi

  local -n host_array_ref=$host_obj
  local dst_host_v4=${host_array_ref[0]}
  local dst_host_v6=${host_array_ref[1]}

  local dst_protocol=${port_array_ref[0]}
  local dst_wan_port=${port_array_ref[1]}
  local dst_lan_port=${port_array_ref[1]}

  # The 3rd argument can be used to map the service port to a custom internal port.
  if [[ -n $3 ]]; then
    dst_lan_port=$3
  fi

  echo "Setting up port forwarding for $host_obj $port_obj $dst_host_v4 $dst_host_v6 $dst_protocol $dst_wan_port $dst_lan_port..."

  #### IPv4 ####
  # Set up DNAT
  nft add rule ip nat prerouting ip daddr $WAN_IPv4 $dst_protocol dport $dst_wan_port dnat to $dst_host_v4:$dst_lan_port
  # Ensure that traffic forward is allowed
  nft add rule ip filter forward ip daddr $WAN_IPv4 iifname $WAN oifname $LAN $dst_protocol dport $dst_wan_port accept
  # Enable hairpin NAT, so that clients connecting to your WAN address end up at the forwarded host
  nft add rule ip nat postrouting ip saddr $LAN_IPv4 ip daddr $dst_host_v4 $dst_protocol dport $dst_wan_port masquerade

  #### IPv6 ####
  if [[ -n "$WAN_IPv6" && -n "$dst_host_v6" ]]; then
    # If we want to mimic a IPv4 NAT using IPv6
    # It is recommended to leave this setting as FALSE
    if [[ "$IPv6_IS_MASQUERADED" == "true" ]]; then
      # Set up DNAT
      nft add rule ip6 nat prerouting ip6 daddr $WAN_IPv6 $dst_protocol dport $dst_wan_port dnat to $dst_host_v6:$dst_lan_port
      # Ensure that traffic forward is allowed
      nft add rule ip6 filter forward ip6 daddr $WAN_IPv6 iifname $WAN oifname $LAN $dst_protocol dport $dst_wan_port accept
      # Enable hairpin NAT, so that clients connecting to your WAN address end up at the forwarded host
      nft add rule ip6 nat postrouting ip6 saddr $LAN_IPv6_ULA ip6 daddr $dst_host_v6 $dst_protocol dport $dst_wan_port masquerade
    else
      # Just forward the traffic to the destination
      nft add rule ip6 filter forward ip6 daddr $dst_host_v6 $dst_protocol dport $dst_wan_port accept
      # Re-write our routers public ip address to the destination ipv6 address
      echo " > Setting up IPv6 rewrite from [$WAN_IPv6] $dst_protocol port $dst_wan_port to [$dst_host_v6]:$dst_lan_port..."
      nft add rule ip6 nat prerouting ip6 daddr $WAN_IPv6 $dst_protocol dport $dst_wan_port dnat to "[$dst_host_v6]:$dst_lan_port"
    fi
  fi
}

# Blocks all traffic FROM and TO the IPv4 address and subnet (if provided).
# Neither the router, nor any clients behind the router will be able to access this address.
block_ipv4() {
  if [ $# -lt 1 ]; then
    echo "Error: block_ipv4: No IP address provided. See the following examples:" >&2
    echo "Error: block_ipv4 8.8.8.8 (Block a single IPv4 address)" >&2
    echo "Error: block_ipv4 8.8.8.8 16 (Block an entire IPv4 subnet)" >&2
    return 1
  fi

  local mask_bits=32
  if [[ -n $2 ]]; then
    mask_bits=$2
  fi

  echo "Blocking all traffic FROM and TO the IPv4 address $1/$mask_bits"
  # Block any access to the router
  nft insert rule ip filter input position 0 iifname $WAN ip saddr $1/$mask_bits drop
  # Block any access from the router
  nft insert rule ip filter output position 0 oifname $WAN ip daddr $1/$mask_bits drop

  # Block any access FROM LAN
  nft insert rule ip filter forward position 0 iifname $LAN ip daddr $1/$mask_bits reject
  nft insert rule ip filter forward position 0 oifname $LAN ip daddr $1/$mask_bits reject
}

# Blocks all traffic FROM and TO the IPv6 address and subnet (if provided).
# Neither the router, nor any clients behind the router will be able to access this address.
block_ipv6() {
  if [ $# -lt 1 ]; then
    echo "Error: block_ipv6: No IP address provided. See the following examples:" >&2
    echo "Error: block_ipv6 2001:4860:4860::8888 (Block a single IPv6 address)" >&2
    echo "Error: block_ipv6 2001:4860:4860::8888 64 (Block an entire IPv6 subnet)" >&2
    return 1
  fi

  local mask_bits=128
  if [[ -n $2 ]]; then
    mask_bits=$2
  fi

  echo "Blocking all traffic FROM and TO the IPv6 address $1/$mask_bits"
  # Block any access to the router
  nft insert rule ip6 filter input position 0 iifname $WAN ip6 saddr $1/$mask_bits drop
  # Block any access from the router
  nft insert rule ip6 filter output position 0 oifname $WAN ip6 daddr $1/$mask_bits drop

  # Block any access FROM LAN
  nft insert rule ip6 filter forward position 0 iifname $LAN ip6 daddr $1/$mask_bits reject
  nft insert rule ip6 filter forward position 0 oifname $LAN ip6 daddr $1/$mask_bits reject
}

# Allows you to monitor all the nftables filters in order to debug your traffic flow.
# You can monitor these traces using "nft monitor trace | grep 8.8.8.8".
debug_filters() {
  echo "Setting up debug filters..."
  # For traffic destined to the local host:
  nft add rule ip filter input position 0 meta nftrace set 1
  # For forwarded traffic:
  nft add rule ip filter forward position 0 meta nftrace set 1
  # For locally generated traffic:
  nft add rule ip filter output position 0 meta nftrace set 1

  nft add rule ip nat prerouting position 0 meta nftrace set 1
  nft add rule ip nat postrouting position 0 meta nftrace set 1
}

# Re-writes all DNS requests originating from our LAN to query our router's DNS server rather than an internet one.
# While all clients should use your own DNS server, enforcing this makes it difficult to diagnose DNS issues.
rewrite_dns() {
  echo "Forcing all IPv4 DNS traffic throught our own router $LAN_ADDR..."
  local port_dns=53

  #### IPv4 ####
  # Re-write DNS requests to our router
  nft add rule ip nat prerouting iifname $LAN ip saddr != $LAN_ADDR ip daddr != $LAN_ADDR udp dport $port_dns dnat to $LAN_ADDR
  nft add rule ip nat prerouting iifname $LAN ip saddr != $LAN_ADDR ip daddr != $LAN_ADDR tcp dport $port_dns dnat to $LAN_ADDR

  #### IPv6 ####
  if [[ -n "$WAN_IPv6" ]]; then
    echo "Forcing all IPv6 DNS traffic throught our own router [$LAN_IPv6_ULA_ADDR]..."
    # Re-write our routers public ip address to the destination ipv6 address
    #    nft add rule ip6 nat prerouting iifname $LAN ip6 daddr != '{ fe80::/10 }' udp dport $port_dns dnat to $LAN_IPv6
    #    nft add rule ip6 nat prerouting iifname $LAN ip6 daddr != '{ fe80::/10 }' tcp dport $port_dns dnat to $LAN_IPv6
    nft add rule ip6 nat prerouting iifname $LAN ip6 saddr != "[$LAN_IPv6_ULA_ADDR]" ip6 daddr != "[$LAN_IPv6_ULA_ADDR]" udp dport $port_dns dnat to "[$LAN_IPv6_ULA_ADDR]"
    nft add rule ip6 nat prerouting iifname $LAN ip6 saddr != "[$LAN_IPv6_ULA_ADDR]" ip6 daddr != "[$LAN_IPv6_ULA_ADDR]" tcp dport $port_dns dnat to "[$LAN_IPv6_ULA_ADDR]"
  fi
}

# Re-writes all NTP requests originating from our LAN to query our router's NTP server rather than an internet one.
# This can improve performace since we have a local one, and ensure that a server is always available (From RTC or internet).
rewrite_ntp() {
  echo "Forcing all IPv4 NTP traffic throught our own router $LAN_ADDR..."
  local port_ntp=123

  #### IPv4 ####
  # Re-write DNS requests to our router
  nft add rule ip nat prerouting iifname $LAN ip saddr != $LAN_ADDR ip daddr != $LAN_ADDR udp dport $port_ntp dnat to $LAN_ADDR

  #### IPv6 ####
  if [[ -n "$WAN_IPv6" ]]; then
    echo "Forcing all IPv6 NTP traffic throught our own router [$LAN_IPv6_ULA_ADDR]..."
    # Re-write our routers public ip address to the destination ipv6 address
    nft add rule ip6 nat prerouting iifname $LAN ip6 saddr != "[$LAN_IPv6_ULA_ADDR]" ip6 daddr != "[$LAN_IPv6_ULA_ADDR]" udp dport $port_ntp dnat to "[$LAN_IPv6_ULA_ADDR]"
  fi
}
