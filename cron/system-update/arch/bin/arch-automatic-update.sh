#!/usr/bin/env bash
# Exit if a non-0 is returned
set -euo pipefail

DIR_LOG="/var/log/kira-router"
FILE_LOG="$DIR_LOG/arch-automatic-update.txt"
mkdir -p "$DIR_LOG"

UPTIME=$(< /proc/uptime)
UPTIME=${UPTIME%%.*}
if [ "$UPTIME" -lt 3600 ]; then
  echo "Skipping updates because system just booted"
  exit 0
fi

echo "Today is $(date)" > $FILE_LOG
echo "Upgrading packages..." >> $FILE_LOG
pacman -Syu --noconfirm >> $FILE_LOG
echo "Rebooting..." >> $FILE_LOG
systemctl reboot
