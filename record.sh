#!/usr/bin/env bash
#
# Record the display with ffmpeg and extra features.

# Prompt user
echo "1) Record display with desktop audio"
echo "2) Record display with microphone audio"
echo "3) Record microphone audio"
echo -n "> "
read src

if [ $src != 3 ]; then
    echo -n "Enter target framerate: "
    read fps
fi

# Determine resolution if needed
if [ $src != 3 ]; then
    res=$(xdpyinfo | awk '/dimensions/{print $2}')
fi

# Record display
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
