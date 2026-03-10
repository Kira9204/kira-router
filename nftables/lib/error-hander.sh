#!/usr/bin/env bash
# Error handler - prints the failing command and exits
on_error() {
  local exit_code=$?
  local line_no=$1
  local cmd=$2

  echo -e "\e[31m[ERROR]\e[0m Command failed at line $line_no with exit code $exit_code: $cmd" 1>&2
  exit $exit_code
}

# Enables strict mode and registers the error trap
enable_strict_mode() {
  set -Eeuo pipefail
  trap 'on_error $LINENO "$BASH_COMMAND"' ERR
}
