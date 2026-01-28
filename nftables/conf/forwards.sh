#!/usr/bin/env bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || {
  echo "This file must be sourced, not executed" 1>&2
  exit 1
}

# This configuration file declares what port forwards should be set up on the router.
# Each forward is declared as a bash associative array. Just copy and paste the examples below

###### Open Ports ######
# Declare the ports you want to open on the router itself.
# This works for both IPv4 and IPv6.
# Each open port is an associative array with the following keys:
#   protocol: "tcp" or "udp"
#   port: The port number to open
# Example:
# declare -A ssh=([protocol]="tcp" [port]="22")
# GLOBAL_OPEN_PORTS=(ssh ...)

declare -A ssh=([protocol]="tcp" [port]="22")
declare -A wireguard=([protocol]="udp" [port]="51820")
GLOBAL_OPEN_PORTS=(ssh wireguard)

###### Hosts ######
# Declare the diffrent hosts on your LAN that you want to forward ports to.
# This works for both IPv4 and IPv6. In the case of IPv6,
# traffic will be forwarded from your WAN interface to the target host's IPv6 address.
# Example:
# declare -A router=([ipv4]="10.0.6.1" [ipv6]="2001:db8:1:2::1")
# declare -A server=([ipv4]="10.0.6.2" [ipv6]="2001:db8:1:2::2")
# GLOBAL_HOSTS=(router server)
#
declare -A router=([ipv4]="10.0.6.1" [ipv6]="2001:db8::1")
declare -A server=([ipv4]="10.0.6.2" [ipv6]="2001:db8::2")
GLOBAL_HOSTS=(router server desktop)

###### Port Forwards ######
# Declare the port forwards you want to set up.
# Each port forward is an associative array with the following keys:
#   protocol: "tcp" or "udp"
#   src_port: The port on the WAN interface to forward from
#   dest_host: The target host on the LAN to forward to (must be one of the declared hosts above)
#   dest_port: The port on the target host to forward to
# Example:
# declare -A http=([protocol]="tcp" [src_port]="80" [dest_port]="80" [dest_host]="server")
# declare -A http=([protocol]="tcp" [src_port]="443" [dest_port]="443" [dest_host]="server")
# GLOBAL_PORT_FORWARDS=(http https)
declare -A http=([protocol]="tcp" [src_port]="80" [dest_port]="80" [dest_host]="server")
declare -A https=([protocol]="tcp" [src_port]="443" [dest_port]="443" [dest_host]="server")
declare -A py=([protocol]="tcp" [src_port]="8000" [dest_port]="8000" [dest_host]="desktop")
GLOBAL_PORT_FORWARDS=()
