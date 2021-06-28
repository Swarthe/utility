#!/usr/bin/sh

updates_repo=$(checkupdates | wc -l)

updates_aur=$(yay -Qum | wc -l)

if [ $(($updates_repo + $updates_aur)) -eq 0 ]; then
    echo " "
else
    echo " $updates_repo | $updates_aur"
fi
