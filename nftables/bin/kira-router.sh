#!/usr/bin/env bash
set -euo pipefail
# DEBUG mode - Prints every command being executed
#set -x
DIR_CONF="/etc/kira-router/nftables"
DIR_LIB="/usr/local/lib/kira-router"
source "$DIR_LIB/common.lib.sh"

source "$DIR_CONF/env.sh"
source "$DIR_CONF/forwards.sh"
source "$DIR_CONF/blocklist.sh"

# ===============================================================
# ========== Initialization and verification Functions ==========
# ===============================================================

verify_required_vars() {
  local missing=0
  local required_vars=(
    "GLOBAL_ILAN_IPV4_ENABLED"
    "GLOBAL_ILAN_IPV6_ENABLED"
    "GLOBAL_IWAN_IPV4_ENABLED"
    "GLOBAL_IWAN_IPV6_ENABLED"
    "GLOBAL_ILAN_NAME"
    "GLOBAL_IWAN_NAME"
    "GLOBAL_ILAN_IPV4_ADDR"
    "GLOBAL_ILAN_IPV4_SUB"
    "GLOBAL_ILAN_IPV4_CDIR"
    "GLOBAL_ILAN_IPV6_ADDR"
    "GLOBAL_ILAN_IPV6_SUB"
    "GLOBAL_ILAN_IPV6_CDIR"
    "GLOBAL_IWAN_IPV4_ADDR"
    "GLOBAL_IWAN_IPV4_SUB"
    "GLOBAL_IWAN_IPV4_CDIR"
    "GLOBAL_IWAN_IPV6_ADDR"
    "GLOBAL_IWAN_IPV6_SUB"
    "GLOBAL_IWAN_IPV6_CDIR"
    "GLOBAL_INTERNET_GATEWAY_MODE_IPV4"
    "GLOBAL_INTERNET_GATEWAY_MODE_IPV6"
  )

  for var in "${required_vars[@]}"; do
    local value="${!var}"
    if [ -z "$value" ]; then
      print_error "Required variable is empty: $var"
      missing=1
    fi
  done

  if [ "$missing" -ne 0 ]; then
    exit 1
  fi
}

resolve_addresses() {
  # LAN IPv4 Address and Subnet
  if [ "$GLOBAL_ILAN_IPV4_ENABLED" == "true" ]; then
    # Resolve ILAN IPv4 Address
    if [ "$GLOBAL_ILAN_IPV4_ADDR" == "auto" ]; then
      GLOBAL_ILAN_IPV4_ADDR=$(get_ipv4_addr $GLOBAL_ILAN_NAME)
      if [ -z "$GLOBAL_ILAN_IPV4_ADDR" ]; then
        print_error "Failed to resolve global IPv4 address for interface $GLOBAL_ILAN_NAME"
        return 1
      fi
    fi

    # Resolve ILAN IPv4 Subnet
    if [ "$GLOBAL_ILAN_IPV4_SUB" == "auto" ]; then
      GLOBAL_ILAN_IPV4_SUB=$(get_ipv4_sub $GLOBAL_ILAN_NAME)
      if [ -z "$GLOBAL_ILAN_IPV4_SUB" ]; then
        print_error "Failed to resolve IPv4 subnet for interface $GLOBAL_ILAN_NAME"
        return 1
      fi

      GLOBAL_ILAN_IPV4_CDIR="$GLOBAL_ILAN_IPV4_ADDR/$GLOBAL_ILAN_IPV4_SUB"
    fi
  fi

  # LAN IPv6 Address and Subnet
  if [ "$GLOBAL_ILAN_IPV6_ENABLED" == "true" ]; then
    # Resolve ILAN IPv6 Address
    if [ "$GLOBAL_ILAN_IPV6_ADDR" == "auto" ]; then
      GLOBAL_ILAN_IPV6_ADDR=$(get_ipv6_addr $GLOBAL_ILAN_NAME)
      if [ -z "$GLOBAL_ILAN_IPV6_ADDR" ]; then
        print_error "Failed to resolve global IPv6 address for interface $GLOBAL_ILAN_NAME"
        return 1
      fi

      GLOBAL_ILAN_IPV6_CDIR="$GLOBAL_ILAN_IPV6_ADDR/$GLOBAL_ILAN_IPV6_SUB"
    fi
  fi

  # WAN IPv4 Address and Subnet
  if [ "$GLOBAL_IWAN_IPV4_ENABLED" == "true" ]; then
    # Resolve IWAN IPv4 Address
    if [ "$GLOBAL_IWAN_IPV4_ADDR" == "auto" ]; then
      GLOBAL_IWAN_IPV4_ADDR=$(get_ipv4_addr $GLOBAL_IWAN_NAME)
      if [ -z "$GLOBAL_IWAN_IPV4_ADDR" ]; then
        print_error "Failed to resolve global IPv4 address for interface $GLOBAL_IWAN_NAME"
        return 1
      fi
    fi

    # Resolve IWAN IPv4 Subnet
    if [ "$GLOBAL_IWAN_IPV4_SUB" == "auto" ]; then
      GLOBAL_IWAN_IPV4_SUB=$(get_ipv4_sub $GLOBAL_IWAN_NAME)
      if [ -z "$GLOBAL_IWAN_IPV4_SUB" ]; then
        print_error "Failed to resolve IPv4 subnet for interface $GLOBAL_IWAN_NAME"
        return 1
      fi

      GLOBAL_IWAN_IPV4_CDIR="$GLOBAL_IWAN_IPV4_ADDR/$GLOBAL_IWAN_IPV4_SUB"
    fi
  fi

  # WAN IPv6 Address and Subnet
  if [ "$GLOBAL_IWAN_IPV6_ENABLED" == "true" ]; then
    # Resolve IWAN IPv6 Address
    if [ "$GLOBAL_IWAN_IPV6_ADDR" == "auto" ]; then
      GLOBAL_IWAN_IPV6_ADDR=$(get_ipv6_addr $GLOBAL_IWAN_NAME)
      if [ -z "$GLOBAL_IWAN_IPV6_ADDR" ]; then
        print_error "Failed to resolve global IPv6 address for interface $GLOBAL_IWAN_NAME"
        return 1
      fi

      GLOBAL_IWAN_IPV6_CDIR="$GLOBAL_IWAN_IPV6_ADDR/$GLOBAL_IWAN_IPV6_SUB"
    fi
  fi
}

wait_until_network_is_configured() {
  print_info "Waiting until network interfaces are configured..."
  local attempts=0
  local max_attempts="${WAIT_MAX_ATTEMPTS:-60}"
  local sleep_seconds="${WAIT_SLEEP_SECONDS:-1}"

  until resolve_addresses; do
    attempts=$((attempts + 1))
    if [ "$attempts" -ge "$max_attempts" ]; then
      print_error "Network interfaces not configured after $attempts attempts."
      exit 1
    fi
    print_warn "Network not ready yet, retrying in ${sleep_seconds}s... ($attempts/$max_attempts)"
    sleep "$sleep_seconds"
  done

  print_info "Network interfaces successfully resolved."
}

verify_addresses() {
  # Verify ILAN IPv4 address and subnet
  if [ "$GLOBAL_ILAN_IPV4_ENABLED" == "true" ]; then
    if ! ipcalc -c $GLOBAL_ILAN_IPV4_CDIR > /dev/null 2>&1; then
      print_error "Invalid ILAN IPv4 address or subnet: $GLOBAL_ILAN_IPV4_CDIR"
      exit 1
    fi
  fi
  # Verify ILAN IPv6 address and subnet
  if [ "$GLOBAL_ILAN_IPV6_ENABLED" == "true" ]; then
    # Verify ILAN IPv6 Address
    if ! ipcalc -6 -c $GLOBAL_ILAN_IPV6_CDIR > /dev/null 2>&1; then
      print_error "Invalid ILAN IPv6 address or subnet: $GLOBAL_ILAN_IPV6_CDIR"
      exit 1
    fi
  fi

  # Verify IWAN IPv4 address and subnet
  if [ "$GLOBAL_IWAN_IPV4_ENABLED" == "true" ]; then
    # Verify IWAN IPv4 Address
    if ! ipcalc -c $GLOBAL_IWAN_IPV4_CDIR > /dev/null 2>&1; then
      print_error "Invalid IWAN IPv4 address or subnet: $GLOBAL_IWAN_IPV4_CDIR"
      exit 1
    fi
  fi
  # Verify IWAN IPv6 address and subnet
  if [ "$GLOBAL_IWAN_IPV6_ENABLED" == "true" ]; then
    # Verify IWAN IPv6 Address
    if ! ipcalc -6 -c $GLOBAL_IWAN_IPV6_CDIR > /dev/null 2>&1; then
      print_error "Invalid IWAN IPv6 address or subnet: $GLOBAL_IWAN_IPV6_CDIR"
      exit 1
    fi
  fi
}

verify_hosts() {
  for name in "${GLOBAL_HOSTS[@]}"; do
    local ipv4=$(eval "echo \${${name}[ipv4]}")
    local ipv6=$(eval "echo \${${name}[ipv6]}")

    if [ -n "$ipv4" ]; then
      if ! ipcalc -c $ipv4 > /dev/null 2>&1; then
        print_error "Invalid IPv4 address for host $name: $ipv4"
        exit 1
      fi
    fi

    if [ -n "$ipv6" ]; then
      if ! ipcalc -6 -c $ipv6 > /dev/null 2>&1; then
        print_error "Invalid IPv6 address for host $name: $ipv6"
        exit 1
      fi
    fi
  done
}

verify_ports() {
  for name in "${GLOBAL_OPEN_PORTS[@]}"; do
    local port=$(eval "echo \${${name}[port]}")

    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
      print_error "Invalid port number for open port $name: $port"
      exit 1
    fi
  done

  for name in "${GLOBAL_PORT_FORWARDS[@]}"; do
    local src_port=$(eval "echo \${${name}[src_port]}")
    local dest_port=$(eval "echo \${${name}[dest_port]}")

    if ! [[ "$src_port" =~ ^[0-9]+$ ]] || [ "$src_port" -lt 1 ] || [ "$src_port" -gt 65535 ]; then
      print_error "Invalid source port number for port forward $name: $src_port"
      exit 1
    fi

    if ! [[ "$dest_port" =~ ^[0-9]+$ ]] || [ "$dest_port" -lt 1 ] || [ "$dest_port" -gt 65535 ]; then
      print_error "Invalid destination port number for port forward $name: $dest_port"
      exit 1
    fi
  done
}

print_resolved_env() {
  print_info "Resolved Environment Variables:"
  print_info "------ Interfaces -----"
  print_info "GLOBAL_ILAN_NAME: $GLOBAL_ILAN_NAME"
  print_info "GLOBAL_ILAN_IPV4_ENABLED: $GLOBAL_ILAN_IPV4_ENABLED"
  print_info "GLOBAL_ILAN_IPV4_ADDR: $GLOBAL_ILAN_IPV4_ADDR"
  print_info "GLOBAL_ILAN_IPV4_SUB: $GLOBAL_ILAN_IPV4_SUB"
  print_info "GLOBAL_ILAN_IPV4_CDIR: $GLOBAL_ILAN_IPV4_CDIR"
  print_info "GLOBAL_ILAN_IPV6_ENABLED: $GLOBAL_ILAN_IPV6_ENABLED"
  print_info "GLOBAL_ILAN_IPV6_ADDR: $GLOBAL_ILAN_IPV6_ADDR"
  print_info "GLOBAL_ILAN_IPV6_SUB: $GLOBAL_ILAN_IPV6_SUB"
  print_info "GLOBAL_ILAN_IPV6_CDIR: $GLOBAL_ILAN_IPV6_CDIR"

  print_info "GLOBAL_IWAN_NAME: $GLOBAL_IWAN_NAME"
  print_info "GLOBAL_IWAN_IPV4_ENABLED: $GLOBAL_IWAN_IPV4_ENABLED"
  print_info "GLOBAL_IWAN_IPV4_ADDR: $GLOBAL_IWAN_IPV4_ADDR"
  print_info "GLOBAL_IWAN_IPV4_SUB: $GLOBAL_IWAN_IPV4_SUB"
  print_info "GLOBAL_IWAN_IPV4_CDIR: $GLOBAL_IWAN_IPV4_CDIR"
  print_info "GLOBAL_IWAN_IPV6_ENABLED: $GLOBAL_IWAN_IPV6_ENABLED"
  print_info "GLOBAL_IWAN_IPV6_ADDR: $GLOBAL_IWAN_IPV6_ADDR"
  print_info "GLOBAL_IWAN_IPV6_SUB: $GLOBAL_IWAN_IPV6_SUB"
  print_info "GLOBAL_IWAN_IPV6_CDIR: $GLOBAL_IWAN_IPV6_CDIR"
  print_info "------ Internet Gateway Settings -----"
  print_info "GLOBAL_INTERNET_GATEWAY_MODE_IPV4: $GLOBAL_INTERNET_GATEWAY_MODE_IPV4 (Firewalled)"
  print_info "GLOBAL_INTERNET_GATEWAY_MODE_IPV6: $GLOBAL_INTERNET_GATEWAY_MODE_IPV6 (Firewalled)"
  print_info ""
  print_info "------ Hosts -----"
  for name in "${GLOBAL_HOSTS[@]}"; do
    local ipv4=$(eval "echo \${${name}[ipv4]}")
    local ipv6=$(eval "echo \${${name}[ipv6]}")
    print_info "Host: Name: $name. IPv4: $ipv4. IPv6: $ipv6"
  done
  print_info "------------------"
  print_info "------ Open Ports -----"
  for name in "${GLOBAL_OPEN_PORTS[@]}"; do
    local protocol=$(eval "echo \${${name}[protocol]}")
    local port=$(eval "echo \${${name}[port]}")
    print_info "Port: Name: $name. Protocol: $protocol. Port: $port"
  done
  print_info "-----------------------"
  print_info "------ Forwarded Ports -----"
  for name in "${GLOBAL_PORT_FORWARDS[@]}"; do
    local protocol=$(eval "echo \${${name}[protocol]}")
    local src_port=$(eval "echo \${${name}[src_port]}")
    local dest_port=$(eval "echo \${${name}[dest_port]}")
    local dest_host=$(eval "echo \${${name}[dest_host]}")
    print_info "Forward: Name: $name. Protocol: $protocol. Src Port: $src_port. Dest Port: $dest_port. Dest Host: $dest_host"
  done
  print_info "----------------------------"
  print_info "------ Blocked IPv4 ranges -----"
  for range in "${GLOBAL_IPV4_BLOCKLIST[@]}"; do
    print_info "Blocked IPv4 Range: $range"
  done
  print_info "--------------------------------"
  print_info "------ Blocked IPv6 ranges -----"
  for range in "${GLOBAL_IPV6_BLOCKLIST[@]}"; do
    print_info "Blocked IPv6 Range: $range"
  done
  print_info "--------------------------------"
}

# =====================================
# ========== Kernel modules ===========
# =====================================

kernel_modules_load() {
  print_info "Loading required kernel modules for nftables router functionality..."
  modprobe nf_conntrack
}

# =====================================
# ========== Sysctl Settings ==========
# =====================================

systctl_apply() {
  print_info "Applying sysctl tweaks for router functionality..."

  #### Enable IPv4 forwarding ####
  # Defaults
  sysctl -w net.ipv4.ip_forward=1
  sysctl -w net.ipv4.conf.default.forwarding=1
  sysctl -w net.ipv4.conf.all.forwarding=1
  # Interfaces
  sysctl -w net.ipv4.conf.wan.forwarding=1
  sysctl -w net.ipv4.conf.lan.forwarding=1

  #### Enable IPv6 forwarding ####
  # Defaults
  sysctl -w net.ipv6.conf.default.forwarding=1
  sysctl -w net.ipv6.conf.all.forwarding=1
  # Interfaces
  sysctl -w net.ipv6.conf.wan.forwarding=1
  sysctl -w net.ipv6.conf.lan.forwarding=1

  #### Extra optimizations ####

  # From Open-WRT
  sysctl -w kernel.panic=3 # Restart if we encounter a kernel panic
  sysctl -w net.core.bpf_jit_enable=1
  sysctl -w net.core.bpf_jit_kallsyms=1
  sysctl -w net.ipv4.conf.default.arp_ignore=1
  sysctl -w net.ipv4.conf.all.arp_ignore=1
  sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1
  sysctl -w net.ipv4.icmp_ignore_bogus_error_responses=1
  sysctl -w net.ipv4.igmp_max_memberships=100
  sysctl -w net.ipv4.tcp_fin_timeout=30
  sysctl -w net.ipv4.tcp_keepalive_time=120
  sysctl -w net.ipv4.tcp_syncookies=1
  sysctl -w net.ipv4.tcp_timestamps=1
  sysctl -w net.ipv4.tcp_sack=1
  sysctl -w net.ipv4.tcp_dsack=1

  # Available ports (IPv6 uses the same value)
  sysctl -w net.ipv4.ip_local_port_range="1024 65535"
  # TCP connection timeouts tuning
  sysctl -w net.netfilter.nf_conntrack_tcp_timeout_established=1800 # default 7440 (2h). 30 mins
  sysctl -w net.netfilter.nf_conntrack_tcp_timeout_close_wait=60    # default 60
  sysctl -w net.netfilter.nf_conntrack_tcp_timeout_fin_wait=30      # default 120
  sysctl -w net.netfilter.nf_conntrack_tcp_timeout_time_wait=30     # default 120
  # UDP connection timeouts tuning
  sysctl -w net.netfilter.nf_conntrack_udp_timeout=60
  sysctl -w net.netfilter.nf_conntrack_udp_timeout_stream=180

  # Conntrack
  sysctl -w net.netfilter.nf_conntrack_acct=1
  sysctl -w net.netfilter.nf_conntrack_buckets=65536
  sysctl -w net.netfilter.nf_conntrack_max=262144
  sysctl -w net.netfilter.nf_conntrack_tcp_timeout_established=7200
  sysctl -w net.netfilter.nf_conntrack_udp_timeout=60
  sysctl -w net.netfilter.nf_conntrack_udp_timeout_stream=180
}

# ========================================
# ========== NFTables Functions ==========
# ========================================

nft_clear_all() {
  print_info "Clearing existing nftables rules..."
  nft list tables \
    | while read table; do
      nft delete $table
    done
}

nft_setup_baseline() {
  print_info "Setting up nftables baseline rules..."

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
  nft add rule ip filter input iifname $GLOBAL_ILAN_NAME accept
  nft add rule ip filter forward iifname $GLOBAL_ILAN_NAME accept
  # Allow all forwards that have a DNAT destination
  nft add rule ip filter forward ct status dnat accept

  #### IPv6 configuration ####
  nft add rule ip6 filter input iifname $GLOBAL_ILAN_NAME accept
  nft add rule ip6 filter forward iifname $GLOBAL_ILAN_NAME accept
  # Allow all forwards that have a DNAT destination
  nft add rule ip6 filter forward ct status dnat accept
}

nft_open_router_ports() {
  for name in "${GLOBAL_OPEN_PORTS[@]}"; do
    local protocol=$(eval "echo \${${name}[protocol]}")
    local port=$(eval "echo \${${name}[port]}")
    print_info "Opening router port: Name: $name. Protocol: $protocol. Port: $port"

    if [ "$GLOBAL_IWAN_IPV4_ENABLED" == "true" ]; then
      nft add rule ip filter input ip daddr $GLOBAL_IWAN_IPV4_ADDR $protocol dport $port accept
    else
      print_warn "Skipping IPv4 open for $name since IWAN IPv4 is disabled..."
    fi

    if [ "$GLOBAL_IWAN_IPV6_ENABLED" == "true" ]; then
      nft add rule ip6 filter input ip6 daddr $GLOBAL_IWAN_IPV6_ADDR $protocol dport $port accept
    else
      print_warn "Skipping IPv6 open for $name since IWAN IPv6 is disabled..."
    fi
  done
}

# Performs IPv4 masquerading (NAT)
nft_masquerade_ipv4() {
  if [ "$GLOBAL_IWAN_IPV4_ENABLED" == "true" ]; then
    print_info "Setting up IPv4 masquerading (NAT)..."
    nft add rule ip nat postrouting ip saddr "$GLOBAL_ILAN_IPV4_CDIR" oifname "$GLOBAL_IWAN_NAME" masquerade
  else
    print_warn "Skipping IPv4 masquerading since IWAN IPv4 is disabled..."
  fi
}

# Maskquerade (NAT) the following IPv6 ULA subnet.
# Since everyone has a public IPv6 address thru IPv6 prefix delegateion, there will typically never be a need for address translations,
# traffic is normally FORWARDED between the interfaces based upon the connection session state.
# Use this if you for whatever reason are going for a ULA network to mirror an IPv4 nat
nft_masquerade_ipv6() {
  if [ "$GLOBAL_IWAN_IPV6_ENABLED" == "true" ]; then
    print_info "Setting up IPv6 masquerading (NAT)..."
    nft add rule ip6 nat postrouting ip6 saddr "$GLOBAL_ILAN_IPV6_ULA_CDIR" oifname "$GLOBAL_IWAN_NAME" masquerade
  else
    print_warn "Skipping IPv6 masquerading since IWAN IPv6 is disabled..."
  fi
}

nft_masquerade() {
  if [ "$GLOBAL_INTERNET_GATEWAY_MODE_IPV4" == "NAT" ]; then
    nft_masquerade_ipv4
  fi

  if [ "$GLOBAL_INTERNET_GATEWAY_MODE_IPV6" == "NAT" ]; then
    nft_masquerade_ipv6
  fi
}

nft_forward_ports() {
  for name in "${GLOBAL_PORT_FORWARDS[@]}"; do
    local protocol=$(eval "echo \${${name}[protocol]}")
    local src_port=$(eval "echo \${${name}[src_port]}")
    local dest_port=$(eval "echo \${${name}[dest_port]}")
    local dest_host_name=$(eval "echo \${${name}[dest_host]}")
    local dest_host_ipv4=$(eval "echo \${${dest_host_name}[ipv4]}")
    local dest_host_ipv6=$(eval "echo \${${dest_host_name}[ipv6]}")

    print_info "Setting up port forward: Name: $name. Protocol: $protocol. Src Port: $src_port. Dest Port: $dest_port. Dest Host: $dest_host_name. IPv4: $dest_host_ipv4. IPv6: $dest_host_ipv6"

    if [ "$GLOBAL_IWAN_IPV4_ENABLED" == "true" ]; then
      #### IPv4 ####
      # Set up DNAT
      nft add rule ip nat prerouting ip daddr $GLOBAL_IWAN_IPV4_ADDR $protocol dport $src_port dnat to $dest_host_ipv4:$dest_port

      # Accept any forwarded connection that was DNATed (covers WAN→LAN and hairpin LAN→LAN)
      nft add rule ip filter forward ct status dnat accept

      # Hairpin SNAT only for DNATed flows (prevents SNAT on plain LAN→LAN)
      #nft add rule ip nat postrouting ip saddr $dest_host_ipv4 ct status dnat masquerade
      nft add rule ip nat postrouting ip saddr $dest_host_ipv4 oifname $GLOBAL_ILAN_NAME ct status dnat masquerade
    else
      print_warn "Skipping IPv4 forward for $name since IWAN IPv4 is disabled..."
    fi

    if [ "$GLOBAL_IWAN_IPV6_ENABLED" == "true" ]; then
      if [ "$GLOBAL_INTERNET_GATEWAY_MODE_IPV6" == "FORWARD" ]; then
        # Accept any DNATed forward
        nft add rule ip6 filter forward ct status dnat accept
        nft add rule ip6 nat prerouting ip6 daddr $GLOBAL_IWAN_IPV6_ADDR $protocol dport $src_port dnat to "[$dest_host_ipv6]:$dest_port"
      elif [ "$GLOBAL_INTERNET_GATEWAY_MODE_IPV6" == "NAT" ]; then
        # Set up DNAT
        nft add rule ip6 nat prerouting ip6 daddr $GLOBAL_IWAN_IPV6_ADDR $protocol dport $src_port dnat to "[$dest_host_ipv6]:$dest_port"

        # Accept any DNATed forward
        nft add rule ip6 filter forward ct status dnat accept
        # (or, if you prefer, match the post-DNAT dest specifically)
        # nft add rule ip6 filter forward ip6 daddr $dst_host_v6 $dst_protocol dport $dst_lan_port accept

        # Hairpin SNAT only when DNATed
        #nft add rule ip6 nat postrouting ip6 saddr $GLOBAL_ILAN_IPV6_CDIR ct status dnat masquerade
        nft add rule ip6 nat postrouting ip6 saddr $GLOBAL_ILAN_IPV6_CDIR oifname $GLOBAL_ILAN_NAME ct status dnat masquerade
      fi
    else
      print_warn "Skipping IPv6 forward for $name since IWAN IPv6 is disabled..."
    fi
  done
}

nft_block_ipv4_cdir() {
  if [ "$GLOBAL_IWAN_IPV4_ENABLED" == "true" ]; then
    for cdir in "${GLOBAL_IPV4_BLOCKLIST[@]}"; do
      print_info "Blocking all traffic FROM and TO the IPv4 address range: $cdir"
      # Block any access to the router
      nft insert rule ip filter input position 0 iifname $GLOBAL_IWAN_NAME ip saddr $cdir drop
      # Block any access from the router
      nft insert rule ip filter output position 0 oifname $GLOBAL_IWAN_NAME ip daddr $cdir drop
      # Block any access FROM LAN
      nft insert rule ip filter forward position 0 iifname $GLOBAL_ILAN_NAME ip daddr $cdir reject
      nft insert rule ip filter forward position 0 oifname $GLOBAL_ILAN_NAME ip daddr $cdir reject
    done
  else
    print_warn "Skipping IPv4 block for $cdir since IWAN IPv4 is disabled..."
  fi
}

nft_block_ipv6_cdir() {
  if [ "$GLOBAL_IWAN_IPV6_ENABLED" == "true" ]; then
    for cdir in "${GLOBAL_IPV6_BLOCKLIST[@]}"; do
      print_info "Blocking all traffic FROM and TO the IPv6 address range: $cdir"
      # Block any access to the router
      nft insert rule ip6 filter input position 0 iifname $GLOBAL_IWAN_NAME ip6 saddr $cdir drop
      # Block any access from the router
      nft insert rule ip6 filter output position 0 oifname $GLOBAL_IWAN_NAME ip6 daddr $cdir drop
      # Block any access FROM LAN
      nft insert rule ip6 filter forward position 0 iifname $GLOBAL_ILAN_NAME ip6 daddr $cdir reject
      nft insert rule ip6 filter forward position 0 oifname $GLOBAL_ILAN_NAME ip6 daddr $cdir reject
    done
  else
    print_warn "Skipping IPv6 block for $cdir since IWAN IPv6 is disabled..."
  fi
}

print_info "===================================="
print_info "====== Kira Router project V2 ======"
print_info "===================================="
print_info ""
verify_root
fail_if_not_installed ip nft ipcalc grep awk cut head ping

setup() {
  # Verification
  verify_required_vars
  wait_until_network_is_configured
  verify_addresses
  verify_hosts
  verify_ports
  print_resolved_env
  print_info ""
  print_info "====== Environment setup complete ======"
  print_info ""
  print_info "====== Loading Kernel modules ======"
  kernel_modules_load
  print_info "====== Kernel modules loaded ======"
  systctl_apply
  print_info "====== Sysctl settings applied ======"

  print_info "====== Setting up nftables ======"
  # NFTables setup
  nft_clear_all
  nft_setup_baseline
  nft_open_router_ports
  nft_masquerade
  nft_forward_ports
  nft_block_ipv4_cdir
  nft_block_ipv6_cdir
  print_info ""
  print_info "====== NFTables setup complete ======"
  print_info ""
  print_info "You can view the current nftables rules with: nft list ruleset"
  print_info "You can monitor nftables logs with: nft monitor trace"
  print_info ""
}

teardown() {
  nft_clear_all
  print_info "====== NFTables cleanup complete ======"
}

# ===== Main execution controlled by first argument =====
CMD="${1:-start}"
case "$CMD" in
  start)
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
