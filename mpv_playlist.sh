#!/usr/bin/env bash

#Shuffle and play music from a directory

#Playing audio with mpv
if [ -e "$1" ]; then
  mpv --shuffle --no-video --term-osd-bar "$1"
else
  echo "Invalid input!"
  echo "Syntax: mpv_playlist.sh [path to audio]"
  exit 1
fi  
