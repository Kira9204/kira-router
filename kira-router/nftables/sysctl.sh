#!/usr/bin/env bash
#
# By: Erik Welander (erik.welander@hotmail.com) https://github.com/Kira9204
# Kira Router - A complete IPv4 and IPv6 router solution based on systemd-networkd, nftables and dnsmasq.
# This script sets up the system's sysctl parameters for IPv4 and IPv6 forwarding.
#

# Exit if a non-0 is returned
set -e

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
