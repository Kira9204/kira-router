# Your DigitalOcean API token with permissions to manage DNS records for the zones you want to update.
DO_TOKEN=""

# Set these to "auto" to automatically detect the current public IPs of the router.
MY_IP_V4="auto"
MY_IP_V6="auto"

# List of DigitalOcean DNS zones to update
# Example: DO_ZONES=("kira.rip" "example.com")
DO_ZONES=()

# List of record names to update with current IP
# Example: DO_IPV4_NAMES=("@" "home")
DO_IPV4_NAMES=("@")
DO_IPV6_NAMES=("@")
