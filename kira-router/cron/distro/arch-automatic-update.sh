#!/usr/bin/env zsh
# Exit if a non-0 is returned
set -e

# This script should NOT run on boot! Verify with this line first!
#echo "ohno" > /root/simple-linux-router/cron/distro/ohno.txt
local logfile=/root/kira-router/cron/distro/log.txt

echo "Today is $(date)" > $logfile
pacman -Syu --noconfirm >> $logfile
reboot
