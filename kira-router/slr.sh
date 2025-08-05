#!/usr/bin/env bash
VERSION="2024-05-28 by erikwelander.se"
PHOME=/root/simple-linux-router
LIB="$PHOME/lib/common.sh"
if [[ ! -f "$LIB" ]]; then
  echo "Could not find $LIB file to import!"
  exit 1
fi
source "$LIB"
export SYSTEMD_PAGER=

WAN=wan
LAN=lan
EDITOR=vim
DIR_NFTABLES="$PHOME/nftables"
DIR_DNSMASQ="/etc/dnsmasq.d"

run() {
  clear
  eval "$@"
  echo
  echo "Press any key to continue..."
  read -rsk1
}

restart_networkd() {
  clear
  systemctl daemon-reload
  systemctl restart systemd-networkd
  systemctl status systemd-networkd
  echo
  echo "Press any key to continue..."
  read -rsk1
}

restart_dnsmasq() {
  clear
  systemctl restart dnsmasq
  systemctl status dnsmasq
  echo
  echo "Press any key to continue..."
  read -rsk1
}

menu="
  1. Edit Nftables and reload the service
  2. List NFtables rules
  3. Edit DHCP settings and reload the service
  4. Read dhcp leases
  5. Edit DNS settings and reload the service
  6. Read $WAN status
  7. Read $LAN status
  8. Read all status
  9. Restart networkd
  w. Edit $WAN interface and restart networkd
  l. Edit $LAN interface and restart networkd
  q. Quit


  Enter choice: "

while true; do

  clear
  local wan_ipv4=$(get_global_ipv4_addr $WAN)
  local wan_ipv6=$(get_global_ipv6_addr $WAN)

  local lan_ipv4=$(get_global_ipv4_addr $LAN)
  local lan_ipv6=$(get_global_ipv6_addr $LAN)

  header="
  Simple Linux Router
  $VERSION

  $WAN IPv4: $wan_ipv4
  $WAN IPv6: $wan_ipv6
  $LAN IPv4: $lan_ipv4
  $LAN IPv6: $lan_ipv6
  "

  echo -n "$header"
  echo -n "$menu"
  read -rsk1 c

  case $c in

    1)
      $EDITOR "$DIR_NFTABLES/start.sh"
      local wd=$(pwd)
      cd "$DIR_NFTABLES"
      run "./start.sh && echo Done!"
      cd "$wd"
      ;;
    2)
      nft list ruleset | more
      ;;

    3)
      $EDITOR "$DIR_DNSMASQ/dhcp.d/dhcp.conf"
      restart_dnsmasq
      ;;

    4)
      cat "$DIR_DNSMASQ/dhcp.d/dhcp.leases" | more
      read -rsk1 c
      ;;
    5)
      $EDITOR "$DIR_DNSMASQ/dns.d/dns.conf"
      restart_dnsmasq
      ;;
    6)
      run networkctl status $WAN
      ;;
    7)
      run networkctl status $LAN
      ;;
    8)
      run networkctl status
      ;;
    9)
      run restart_networkd
      ;;
    w)
      $EDITOR "/etc/systemd/network/11-wan.network"
      restart_networkd
      ;;
    l)
      $EDITOR "/etc/systemd/network/21-lan.network"
      restart_networkd
      ;;
    [Qq])
      echo
      break
      ;;
    *) ;;
  esac
done
