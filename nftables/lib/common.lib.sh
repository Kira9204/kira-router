#!/usr/bin/env bash

# Make sure that the script is being sourced, not executed
verify_no_exec() {
  if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    print_error "This file must be sourced, not executed"
    exit 1
  fi
}
verify_no_exec

verify_root() {
  # Make sure that the user is root before proceeding
  if [ "$EUID" -ne 0 ]; then
    print_error "This program cannot run without root privileges"
    exit 1
  fi
}

print_info() {
  echo -e "\e[32m[INFO]\e[0m $1 "
}
print_warn() {
  echo -e "\e[33m[WARN]\e[0m $1 "
}
print_error() {
  echo -e "\e[31m[ERROR]\e[0m $1 " 1>&2
}

# Exits the script if one of the provided commands are not available
# Example: fail_if_not_installed ip nft
fail_if_not_installed() {
  # Loop over all arguments passed to the function
  for cmd in "$@"; do
    if ! command -v "$cmd" > /dev/null 2>&1; then
      print_error "Could not find \"$cmd\" command. Exiting..."
      return 1
    fi
  done
}

# Selects the first non-link-local IPv4 address from the given interface name
# Example: get_ipv4_addr wan
get_ipv4_addr() {
  if [ $# -lt 1 ]; then
    print_error "get_ipv4_addr: This function requires at least one argument."
    print_error "Example usage: get_ipv4_addr wan"
    return 1
  fi
  ip -4 addr show $1 | grep 'global' | awk '{ print $2 }' | cut -f1 -d'/' | head -n 1
}

# Selects the first global scope IPv4 address from the given interface name
# Example: get_global_ipv4_addr wan
get_ipv4_sub() {
  if [ $# -lt 1 ]; then
    print_error "get_ipv4_sub: This function requires at least one argument."
    print_error "Example usage: get_ipv4_sub wan"
    return 1
  fi
  ip -4 addr show $1 | grep 'global' | awk '{ print $2 }' | cut -f2 -d'/' | head -n 1
}

# Selects the first global scope IPv6 address from the given interface name
# Example: get_ipv6_addr wan
get_ipv6_addr() {
  if [ $# -lt 1 ]; then
    print_error "get_ipv6_addr: This function requires at least one argument."
    print_error "Example usage: get_ipv6_addr wan"
    return 1
  fi
  ip -6 addr show $1 | grep 'global' | awk '{ print $2 }' | cut -f1 -d'/' | head -n 1
}

# Selects the first link-local scope IPv6 address from the given interface name
# Example: get_link_local_ipv6_addr lan
get_link_local_ipv6_addr() {
  if [ $# -lt 1 ]; then
    print_error "get_link_local_ipv6_addr: This function requires at least one argument."
    print_error "Example usage: get_link_local_ipv6_addr lan"
    return 1
  fi
  ip -6 addr show $1 | grep 'link' | awk '{ print $2 }' | cut -f1 -d'/' | head -n 1
}

# Returns a substring truncated at the first slash characcter
# Example:
# ip_address=$(split_at_slash "172.28.80.102/32")
# echo $ip_address
split_at_slash() {
  if [ $# -lt 1 ]; then
    print_error "split_string_at_slash: This function requires at least one argument."
    return 1
  fi
  echo "${1%%/*}"
}

# Will ping one or more destination addresses until any responds
# Example: ping_until_successful 1.1.1.1 2606:4700:4700::1111
ping_until_successful() {
  if [ $# -lt 1 ]; then
    print_error "ping_until_successful: This function requires at least one argument."
    print_error "Example usage: ping_until_successful 1.1.1.1 [2606:4700:4700::1111]"
    return 1
  fi

  local targets=("$@")
  print_info "Pinging: ${targets[*]}"

  while true; do
    for target in "${targets[@]}"; do
      ping -c 1 "$target" > /dev/null 2>&1
      if [ $? -eq 0 ]; then
        print_info "Ping to $target successful!"
        return 0
      fi
    done
    print_warn "Ping failed for all targets. Retrying in 1 sec..."
    sleep 1
  done
}

# Downloads a file from a URL and replaces the destination file if the download was successful
# Example: download_and_replace "https://big.oisd.nl/unbound" "/etc/unbound/block.d/oisd.conf"
download_and_replace() {
  if [ $# -lt 2 ]; then
    print_error "download_and_replace: This function requires at least two arguments."
    print_error "Example usage: download_and_replace https://big.oisd.nl/unbound /etc/unbound/block.d/oisd.conf"
    return 1
  fi
  local url="$1"
  local dest="$2"
  local download_temp_headers="$dest.download.headers"
  local download_temp="$dest.download"
  local curl_exit
  local http_code

  print_info "Downloading: ${url}"
  if curl -sS -L -w '%{http_code}' -o "$download_temp" "$url" > "$download_temp_headers"; then
    curl_exit=0
  else
    curl_exit=$?
  fi

  if [ -s "$download_temp_headers" ]; then
    http_code="$(cat "$download_temp_headers")"
  else
    http_code="000"
  fi
  rm -f "$download_temp_headers"

  if [ "$curl_exit" -eq 0 ] && [ "$http_code" -ge 200 ] && [ "$http_code" -lt 400 ]; then
    mv "$download_temp" "$dest"
    chmod 755 "$dest"
    print_info "Updated ${dest} (HTTP ${http_code})."
  else
    rm -f "$download_temp"
    print_error "Download failed (exit=${curl_exit}, HTTP=${http_code}). Keeping existing ${dest}."
  fi
}
