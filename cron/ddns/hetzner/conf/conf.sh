# Your Hetzner API token with permissions to manage DNS records for the zones you want to update.
HZ_TOKEN=""

# Set these to "auto" to automatically detect the current public IPs of the router.
MY_IP_V4="auto"
MY_IP_V6="auto"

# List of Hetzner DNS zones to update
# Example: HZ_ZONES=("kira.rip")
HZ_ZONES=()

# List of record names to update with current IP
# Example: HZ_IPV4_NAMES=("@" "home")
HZ_IPV4_NAMES=("@")
HZ_IPV6_NAMES=("@")
