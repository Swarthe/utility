#!/usr/bin/sh
#
# media.sh: Show MPRIS media status
#
# Licensed under the MIT License. See LICENSE.txt for more information.
#

if [ "$(playerctl status 2> /dev/null)" = "Playing" ]; then
    playerctl metadata -f '{{artist}}    {{title}}' \
    | sed -e 's/ - Topic//g' -e 's/\..*//'
elif [ "$(playerctl status 2> /dev/null)" = "Paused" ]; then
    playerctl metadata -f '{{artist}}    {{title}}' \
    | sed -e 's/ - Topic//g' -e 's/\..*//'
else
    echo
fi
