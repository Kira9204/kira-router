#!/usr/bin/env bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || {
  echo "This file must be sourced, not executed" 1>&2
  exit 1
}

# Add any commands that should be called after the main setup script has run here.
# If your VPN connection contains custom NFTables rules for example,
# you can restart the connection here to apply those rules after the main setup is done.
#
# Example: GLOBAL_POST_SETUP_COMMANDS=("systemctl restart wg-sk.service" ...)
GLOBAL_POST_SETUP_COMMANDS=("systemctl restart wg-sk.service")
