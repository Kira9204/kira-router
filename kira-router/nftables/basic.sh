#
# This script contains only the essentials for a basic router in order to debug
# Why your system isn't routing packets.
# Use ./start.sh when not debugging
#
./sysctl.sh

# Clear all existing rules
nft list tables \
  | while read table; do
    nft delete $table
  done

# Step 1: Define your table structure
# First, let's define the tables. We will use two tables: one for filtering (filter) and one for NAT (nat).
nft add table ip filter
nft add table ip nat

# Step 2: Set up NAT (Network Address Translation)
# These rules will masquerade outbound traffic from your LAN
# so that all outgoing internet requests appear to come from your router's WAN IP address.
#
# It also sets up basic DNAT if needed (you can skip DNAT rules if you do not need port forwarding).
# Add chains for NAT
nft add chain ip nat prerouting { type nat hook prerouting priority 0 \; }
nft add chain ip nat postrouting { type nat hook postrouting priority 100 \; }

# Masquerade traffic from LAN going out to the Internet
nft add rule ip nat postrouting oifname wan masquerade

# Add basic chains
nft add chain ip filter input { type filter hook input priority 0 \; policy drop \; }
nft add chain ip filter forward { type filter hook forward priority 0 \; policy drop \; }
nft add chain ip filter output { type filter hook output priority 0 \; policy accept \; }

# Accept any localhost traffic
nft add rule ip filter input iifname "lo" accept
nft add rule ip filter output oifname "lo" accept

# Accept established and related connections
nft add rule ip filter input ct state related,established accept
nft add rule ip filter forward ct state related,established accept

# Allow ICMP for diagnostic purposes (ping, traceroute)
nft add rule ip filter input ip protocol icmp accept

# LAN to Internet traffic
nft add rule ip filter forward iifname lan oifname wan accept

# Drop invalid packets
nft add rule ip filter input ct state invalid drop
nft add rule ip filter forward ct state invalid drop
