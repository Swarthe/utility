#!/usr/bin/env bash
#
# record: Record the display and desktop or microphone audio with ffmpeg
#
# Copyright (c) 2021 Emil Overbeck <https://github.com/Swarthe>
#
# Subject to the MIT License. See LICENSE.txt for more information.
#

#
# Prompt user
#
echo "1) Record display with desktop audio"
echo "2) Record display with microphone audio"
echo "3) Record microphone audio"
echo -n "> "
read type

#
# Determine resolution if needed
#
if [ "$type" = "1" -o "$type" = "2" ]; then
    echo -n "Enter target framerate: "
    read fps
    resolution="$(xdpyinfo | awk '/dimensions/{print $2}')"
fi

#
# Record display
#
case $type in
1)
    ffmpeg -s "$resolution" -r "$fps" -f x11grab -i :0.0 -f pulse -i \
    pulseeffects_sink out.mkv
    ;;
2)
    ffmpeg -s "$resolution" -r "$fps" -f x11grab -i :0.0 -f pulse -i \
    pulseeffects_source out.mkv
    ;;
3)
    ffmpeg -f pulse -i pulseeffects_source out.wav
    ;;
*)
    echo "Invalid input!"
    exit 1
    ;;
esac
