#!/usr/bin/env bash
#
# By: Erik Welander (erik.welander@hotmail.com) https://github.com/Kira9204
# Kira Router - A complete IPv4 and IPv6 router solution based on systemd-networkd, nftables and dnsmasq.
# This script is the entry point for setting up your router.
#

# Disable paging of output
export SYSTEMD_PAGER=

# Exit if a non-0 is returned
# set -e

# Activate debugging from here
#set -x

# Import functions into our script
import_arr=("../lib/common.sh" "./lib.sh")
for to_import in "${import_arr[@]}"; do
  if [[ ! -f "$to_import" ]]; then
    echo "Could not find $to_import file to import!" >&2
    exit 1
  fi
  source "$to_import"
done
fail_if_not_installed ip nft sysctl

# First We need to declare our interfaces and addresses.
#
# The configuration for your interfaces are located at /etc/systemd/network/* .
# For the sake of clarity and simplicity, you should name your interfaces "lan" and "wan"
# respectively.
#
# On the LAN, we will use:
# * LAN_ADDR:     Static IPv4 address in the private address space
# * LAN_IPv6:     You public IPv6 address assigned to you via DHCP prefix delegation (Or RA)
# * LAN_IPv6_ULA: Static IPv6 address in the private address space, use https://unique-local-ipv6.com/
#
# Depending on your systemd-networkd configuration, you will recieve both
# a "permament"(based on MAC address) IPv6 and a temporary (random) IPv6 address.
#
#### Declare interfaces ####
LAN=lan
LAN_ADDR=10.0.6.1
LAN_SUB=24
LAN_IPv4="$LAN_ADDR/$LAN_SUB"
LAN_IPv6=$(get_global_ipv6_addr $LAN)
LAN_IPv6_ULA_ADDR=
LAN_IPv6_ULA_SUB=48
LAN_IPv6_ULA="$LAN_IPv6_ULA_ADDR/$LAN_IPv6_ULA_SUB"

# The VPN interface, if any.
# You can add this and leave the others empty if you want forwarding between local subnets,
# but don't need to perform NAT.
VPN=wg_sk
# Not needed unless you perform NAT
VPN_ADDR=
VPN_SUB=

# Your public IPv4 and IPv6 addresses will automatically be fetched here,
# and used when setting up nftables rules.
# Do not change these unless you have a static addresses.
WAN=wan
WAN_IPv4=$(get_global_ipv4_addr $WAN)
WAN_IPv6=$(get_global_ipv6_addr $WAN)

print_network_config

# Secondly we need to declare what services we are providing on our network.
# If you want SSH access on ther internet, or if you are running a web server or wireguard VPN service,
# you should add theese here.
#
# See examples below on how to create theese:
# A simple list of name=(<protocol> <port> <enabled>)
# Examples:
# http=(tcp 80 true)
# wireguard=(udp 51820 true)
# some-service=(tcp 22-23 true)
http=(tcp 80 true)
https=(tcp 443 true)

# Thirdly we need to declare what hosts are providing services on our network.
# See examples below on how to create theese:
# host=("<ipv4>" "(optional)<ipv6>").
# Example: server=("10.0.6.2" "82ef:8811:ab45:7c8b:08a3:4201:8d5d:6fde")
#
router=("10.0.6.1" "some-ipv6-address")
server=("10.0.6.2" "some-ipv6-address")

#### Setup ####
# Enable kernel packet forwarding
echo "Setting up Sysctl..."
./sysctl.sh
echo
echo "Setting up NFTables..."

# Clean all rules and set up sane router defaults.
# This allows all LAN traffix on the input and forward chain,
# so there is no need to manually add such rules.
nft_setup_defaults

# Allow all incoming traffic on these interfaces.
# LAN is by default always allowed.
# If you have a VPN interface, add it here
allow_interfaces $VPN

# Maskquerade (NAT) the following IPv4 subnet.
# This enables your local client to access the internet.
masquerade_ipv4 $LAN_ADDR $LAN_SUB $WAN

# Maskquerade (NAT) the following IPv6 ULA subnet.
# Only use this if your ISP does not provide you with an IPv6 prefix delegation.
# This mirrors a classic IPv4 NAT setup.
# Uncomment both lines to activate
#IPv6_IS_MASQUERADED=true
#masquerade_ipv6 $LAN_IPv6_ULA_ADDR $LAN_IPv6_ULA_SUB $WAN

# Open up non-forwarded ports that your router are exposing to the internet here.
# If you want access to your router over ssh for example, add the following: open ssh
# Keep in mind that OpenSSH can listen on multible ports.
# A recommended approach is to only open a custom port here, as the standard port 22 will be allowed on lan
# by default.
#open ssh

# If you are running a wireguard server on your router for example, add the following: open wireguard
open wireguard

# Forward traffic on the internet to your local service on LAN.
# This performs forwarding, DNAT and hairpin-nat for seamless operation.
# Example:
# forward server http
# forward server_2 http <custom internal port>
forward server http
forward server https
#forward server plex

# You can completely block ALL traffic TO and FROM certain IPv4/IPv6 addresses and subnets.
# Examples:
# block_ipv4 8.8.8.8
# block_ipv4 8.8.0.0 16
# block_ipv6 2001:4860:4860::8888
# block_ipv6 2001:4860:4860:: 64

# You can monitor all the nftables filters in order to debug your traffic flow by uncommenting this.
# You can monitor these traces using "nft monitor trace | grep 8.8.8.8".
#debug_filters

# Re-writes all DNS requests originating from our LAN to query our router's DNS server rather than an internet one.
# While all clients should use your own DNS server, enforcing this makes it difficult to diagnose DNS issues.
# It is recommended that you leave this off.
#rewrite_dns

# Re-writes all NTP requests originating from our LAN to query our router's NTP server rather than an internet one.
# If you are running your own NTP server like Chrony, it is recommended that you add the following DNS entries instead:
# time.windows.com time.apple.com time.android.com
#rewrite_ntp
