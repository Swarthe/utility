#!/usr/bin/sh
#
# update.sh: Show number of available pacman and AUR package updates
#
# Licensed under the MIT License. See LICENSE.txt for more information.
#

if [ "$1" = "-r" ]; then
    while pgrep polybar; do
        log_size=$(wc -l < /var/log/pacman.log)
        sleep 5
        if [ $log_size -ne $(wc -l < /var/log/pacman.log) ]; then
            polybar-msg hook update-ipc 1
        fi
    done
    exit
fi

updates_repo=$(checkupdates | wc -l)
updates_aur=$(yay -Qum | wc -l)

if [ $(($updates_repo + $updates_aur)) -eq 0 ]; then
    echo " "
else
    echo "%{F#e60053}%{F-} $updates_repo | $updates_aur"
fi
