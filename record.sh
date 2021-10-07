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

# TODO:
#
# check our i3 config for audio management keybindings for efficient ways to
# manager pipewire devices instead of using pulseeffects devices
#
# add support for recording from camera (also with audio)
# add support for recording display with no audio (individual OPTARG management
# for options)

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
  -d    record the display and specify audio source ('+desktop' for desktop,
          '+microphone' for microphone)
  -c    open a video feed of the camera to take a picture (by pressing 's')
  -m    record only microphone audio
  -f    specify the frame rate from 1 to 480 if recording the display; ignore
          otherwise
  -h    display this help text

Example: record -d+m

Note: You may only specify one source option (these are 'd', 'c', 'm').
EOF
}

err ()
{
    printf '%berror:%b %s\n' "$bold_red" "$normal" "$*" >&2
}

#
# Handle options
#

# Serves to count the number of source options passed
opt_count=0

while getopts :hd:cmf: opt; do
    case "${opt}" in
    h)
        usage; exit
        ;;
    d)
        if [ "$OPTARG" = "+desktop" ]; then
            type='d+d'
        elif [ "$OPTARG" = "+microphone" ]; then
            type='d+m'
        else
            err "Invalid option '$OPTARG'"
            printf '%s\n' "Try 'backup -h' for more information."
        fi

        opt_count+=1
        ;;
    c)
        # mpv can take pictures from camera feed
        type='c'
        opt_count+=1
        ;;
    m)
        type='m'
        opt_count+=1
        ;;
    f)
        if [ $OPTARG -gt 0 -a $OPTARG -le 480 ]; then
            fps="$OPTARG"
        else
            err "Invalid argument '$OPTARG' for option 'f'"
            printf '%s\n' "Try 'record -h' for more information."
            exit 1
        fi
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
# Solve problems
#

# Exit if number of source options is null or greater than 1 to avoid conflicts
# TODO: implement documented defaults, especially for frame rate
if [ $opt_count -eq 0 ]; then
    err "Missing option"
    printf '%s\n' "Try 'record -h' for more information."
    exit 1
elif [ $opt_count -ne 1 ]; then
    err "Specifying multiple source options is not permitted"
    printf '%s\n' "Try 'record -h' for more information."
    exit 1
fi

# Collect or check for necessary information to record the display
if [ "$type" = 'd+d' -o "$type" = 'd+m' ]; then
    if [ $fps ]; then
        resolution="$(xdpyinfo | awk '/dimensions/{print $2}')"
    else
        err "Option 'd' requires the frame rate to be specified with '-f'"
        printf '%s\n' "Try 'record -h' for more information."
        exit 1
    fi

fi

#
# Take the recording
#

case "$type" in
d+d)
    ffmpeg -s "$resolution" -r "$fps" -f x11grab -i :0.0 -f pulse -i \
    pulseeffects_sink out.mkv
    ;;
d+m)
    ffmpeg -s "$resolution" -r "$fps" -f x11grab -i :0.0 -f pulse -i \
    pulseeffects_source out.mkv
    ;;
m)
    ffmpeg -f pulse -i pulseeffects_source out.wav
    ;;
c)
    # mpv can take pictures from camera feed
    mpv av://v4l2:/dev/video0 --profile=low-latency --untimed
    ;;
esac
