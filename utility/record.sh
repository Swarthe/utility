#!/usr/bin/env bash
#
# record: Record the display and desktop or microphone audio
#
# Licensed under the MIT License. See LICENSE.txt for more information.
#

#
# Prompt user
#
echo "1) Record display with desktop audio"
echo "2) Record display with microphone audio"
echo "3) Record microphone audio"
echo -n "> "
read src

#
# Determine resolution if needed
#
if [ "$src" = "1" -o "$src" = "2" ]; then
    echo -n "Enter target framerate: "
    read fps
    res="$(xdpyinfo | awk '/dimensions/{print $2}')"
fi

#
# Record display
#
case $src in
    1) 
        ffmpeg -s "$res" -r "$fps" -f x11grab -i :0.0 -f pulse -i \
        pulseeffects_sink out.mkv
        ;;
    2) 
        ffmpeg -s "$res" -r "$fps" -f x11grab -i :0.0 -f pulse -i \
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
