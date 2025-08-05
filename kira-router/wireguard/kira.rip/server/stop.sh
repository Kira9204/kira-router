#!/usr/bin/env bash
source "./env.sh"

echo "Removing old routes and devices..."
ip -4 route del $ROUTE_KIRA

echo "Removing interface..."
ip link del dev $IVPN

