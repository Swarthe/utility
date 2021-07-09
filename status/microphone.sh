#!/usr/bin/sh
#
# microphone.sh: Show number of processes accessing the microphone
#
# Copyright (c) 2021 Emil Overbeck <https://github.com/Swarthe>
# Licensed under the MIT License. See LICENSE.txt for more information.
#

if ! grep "owner_pid" /proc/asound/card2/pcm0c/sub0/status &> /dev/null; then
    echo ""
else
    echo -e "%{F#e60053}%{F-}"
fi
