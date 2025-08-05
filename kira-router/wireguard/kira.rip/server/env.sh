IVPN=wg_kira_rip
IPv4=10.0.99.1
# Allows traffic back from my home
ROUTE_KIRA="10.0.6.0/24 via 10.0.99.2 dev $IVPN"
