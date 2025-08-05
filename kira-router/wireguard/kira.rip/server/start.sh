#!/usr/bin/env bash
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1


source "./env.sh"

iptables -A INPUT -p icmp -j ACCEPT
iptables -A FORWARD -i $IVPN -j ACCEPT

iptables -A FORWARD -i $IVPN -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o $IVPN -j ACCEPT

./stop.sh

echo "Adding new interface..."
ip link add $IVPN type wireguard
wg setconf $IVPN wg.conf
ip -4 address add "$IPv4/30" dev $IVPN
ip link set $IVPN up

ip -4 route add $ROUTE_KIRA

ping -c 1 10.0.99.2 > /dev/null 2>&1

