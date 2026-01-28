#!/usr/bin/env bash
# Exit if a non-0 is returned
set -euo pipefail

DIR_LOG="/var/log/kira-router"
FILE_LOG="$DIR_LOG/fedora-automatic-update.txt"
mkdir -p "$DIR_LOG"

UPTIME=$(< /proc/uptime)
UPTIME=${UPTIME%%.*}
if [ "$UPTIME" -lt 3600 ]; then
  echo "Skipping updates because system just booted"
  exit 0
fi

echo "Today is $(date)" > $FILE_LOG
echo "Upgrading packages..." >> $FILE_LOG
dnf upgrade --refresh -y >> $FILE_LOG
echo "Removing unused packages..." >> $FILE_LOG
dnf autoremove -y >> $FILE_LOG
# Reboot after updates
echo "==== Rebooting! ====" >> $FILE_LOG
systemctl reboot
