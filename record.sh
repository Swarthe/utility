#!/usr/bin/env bash
#
# record: Record or capture any combination of audio, display and camera with
#         ffmpeg and mpv
#
# An example desktop file for the camera functionality:
#
#   [Desktop Entry]
#   Type=Application
#   Name=Camera
#   GenericName=Picture taker
#   Comment=Take a picture by pressing <s>
#   Exec=record -c
#   Icon=camera
#   Categories=Graphics;
#   Keywords=selfie;picture;
#
# Copyright (c) 2021 Emil Overbeck <https://github.com/Swarthe>
#
# Subject to the MIT License. See LICENSE.txt for more information.
#

# check our i3 config for audio management shortcuts for efficient ways to
# manager pipewire devices
#
# TODO: add support for recording from camera

#
# User I/O functions and variables
#

readonly normal="$(tput sgr0)"
readonly bold="$(tput bold)"
readonly bold_red="${bold}$(tput setaf 1)"

usage ()
{
    cat << EOF
Usage: record [OPTION]...
Record or capture any combination of audio, display and camera.

Options:
  -d    record display and specify audio source ('+d' for desktop, '+m' for
        microphone)
  -c    open a video feed of the camera to take a picture (by pressing 's')
  -m    record only microphone audio
  -h    display this help text


Example: record -d+m
EOF
}

err ()
{
    printf '%berror:%b %s\n' "$bold_red" "$normal" "$*" >&2
}

#
# Handle options
#

# maybe implement defaults
if [ $# -eq 0 ]; then
    err "An option is required"
    printf '%s\n' "Try 'record -h' for more information."
fi

audio_opt ()
{
    if [ "$OPTARG" = "+d" ]; then
        type=1
    elif [ "$OPTARG" = "+m" ]; then
        type=2
    else
        err "Invalid option '$OPTARG'"
        printf '%s\n' "Try 'backup -h' for more information."
    fi
}

while getopts :hd:cm opt; do
    case "${opt}" in
    h)
        usage; exit
        ;;
    d)
        audio_opt
        break
        ;;
    c)
        # mpv can take pictures from camera feed
        mpv av://v4l2:/dev/video0 --profile=low-latency --untimed
        break
        ;;
    m)
        type=3
        break
        ;;
    :)
        err "Option '$OPTARG' requires an argument"
        printf '%s\n' "Try 'record -h' for more information."
        exit 1
        ;;
    \?)
        err "Invalid option '$OPTARG'"
        printf '%s\n' "Try 'record -h' for more information."
        exit 1
        ;;
    esac
done

#
# Run record
#

# Determine resolution if needed
if [ "$type" = "1" -o "$type" = "2" ]; then
    echo -n "Enter target framerate: "
    read fps
    resolution="$(xdpyinfo | awk '/dimensions/{print $2}')"
fi

# Record display
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
esac
