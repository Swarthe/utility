#!/usr/bin/env bash
#
# scot: Capture the display to clipboard or file with magick import
# (intended for use with window managers)
#
# Copyright (c) 2021 Emil Overbeck <https://github.com/Swarthe>
#
# Subject to the MIT License. See LICENSE.txt for more information.
#

#
# User I/O functions and variables
#
if [ $(tput colors) -ge 256 ]; then
    readonly bold_red="\e[1;31m"
    readonly bold_blue="\e[1;34m"
    readonly normal="\033[0m"
fi

usage ()
{
    cat << EOF
Usage: scot [OPTION]
Capture the display.
Unless overriden, capture rectangular selection.

Options:
  -d    capture entire display
  -g    use graphical notifications
  -f    capture to file
  -h    display this help text

Example: scot -nf

Note: Export the 'SCOT_TARGET' variable to set the target for '-f'.
EOF
}

err ()
{
    printf "%berror:%b $*\n" "$bold_red" "$normal" >&2
}

info ()
{
    printf "%binfo:%b $*\n" "$bold_blue" "$normal"
}

#
# Handle options
#
while getopts :hdgf opt; do
    case "${opt}" in
    h)
        usage; exit
        ;;
    d)
        display="1"
        ;;
    g)
        graphical="1"

        err ()
        {
            notify-send -u critical "scot" "$*"
        }

        info ()
        {
            notify-send -i "$target" "scot" "$*"
        }
        ;;
    f)
        file="1"
        ;;
    \?)
        err "Invalid option '$OPTARG'"
        printf '%s\n' "Try 'scot -h' for more information."
        exit 1
        ;;
    esac
done

#
# Take screenshot
#
if [ -z "$file" ]; then
    if [ -z "$display" ]; then
        import png:- | xclip -selection clipboard -t image/png
    else
        import -window root png:- | xclip -selection clipboard -t image/png
    fi
else
    # increment filename to avoid overwriting
    if [ "$SCOT_TARGET" ]; then
        target="$(realpath "${SCOT_TARGET}/screenshot.png")"
        while [ -e "$target" ]; do
            i+=1
            target="$(realpath "${SCOT_TARGET}/screenshot-${i}.png")"
        done
    else
        target="$(realpath screenshot.png)"
        while [ -e "$target" ]; do
            i+=1
            target="$(realpath screenshot-${i}.png)"
        done
    fi

    if [ -z "$display" ]; then
        import "$target" 2> /dev/null
    else
        import -window root "$target" 2> /dev/null
    fi
fi

#
# Announce or notify
#
if [ "$graphical" ]; then
    if [ -z "$file" ]; then
        info "Screenshot successful"
    elif [ -e "$target" ]; then
        info "Screenshot is '$target'"
    else
        err "Could not save screenshot"
    fi
elif [ "$file" ]; then
    if [ -e "$target" ]; then
        info "Screenshot is '$target'"
    else
        err "Could not save screenshot"
    fi
fi
