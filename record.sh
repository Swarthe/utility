#!/usr/bin/env bash

# Record display and audio with ffmpeg and extra features

# Prompt user
echo "1) Record with desktop audio"
echo "2) Record with microphone audio"
echo -n "> "
read src
echo -n "Enter target framerate: "
read fps

# Determine resolution
res=$(xdpyinfo | awk '/dimensions/{print $2}')

# Record display
if [ "$src" == "1" ]; then
  ffmpeg -s "$res" -r "$fps" -f x11grab -i :0.0 -f pulse -i pulseeffects_sink out.mkv
elif [ "$src" == "2" ]; then
  ffmpeg -s "$res" -r "$fps" -f x11grab -i :0.0 -f pulse -i pulseeffects_source out.mkv
else
  echo "Invalid input!"
  exit 1
fi
