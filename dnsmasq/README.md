## DNSMASQ
DNSMASQ is a very lightweight DHCPv4, DHCPv6, SLAAC, DNS and TFTP server, typically used on consumer home routers.  
It is very powerful and easy to configure, but i've personally found that Systemd-networkd and Unbound to handle tasks outside of DHCPv4 a lot better.

From personal experience, DNS packets and SLAAC messages occasionally gets dropped when using DNSMASQ.  
For DHCPv4 duties however, i've found that it performs exellent.
