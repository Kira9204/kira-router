#!/usr/bin/env bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || {
  echo "This file must be sourced, not executed" 1>&2
  exit 1
}

# This configuration file declares IP blocklists to be applied on the router.
# Each blocklist is an array of CDIR notation IP ranges.
# Example:
# GLOBAL_IPV4_BLOCKLIST=("1.1.1.1/8" ...)
GLOBAL_IPV4_BLOCKLIST=()

# This configuration file declares IPv6 blocklists to be applied on the router.
# Each blocklist is an array of CDIR notation IP ranges.
# Example:
# GLOBAL_IPV6_BLOCKLIST=("2001:db8::/32" ...)
GLOBAL_IPV6_BLOCKLIST=()
