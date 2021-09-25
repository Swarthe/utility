#!/usr/bin/env bash
#
# scot: Capture the display to clipboard or file with ImageMagick
#
# An example configuration for i3 integration:
#
#   bindsym $mod+s --release exec --no-startup-id scot
#   bindsym $mod+Shift+s --release exec --no-startup-id scot -f
#   bindsym $mod+$sup+s exec --no-startup-id scot -d
#   bindsym $mod+$sup+Shift+s exec --no-startup-id scot -df
#
# Copyright (c) 2021 Emil Overbeck <https://github.com/Swarthe>
#
# Subject to the MIT License. See LICENSE.txt for more information.
#

#
# User I/O functions and variables
#

readonly normal="$(tput sgr0)"
readonly bold="$(tput bold)"
readonly bold_red="${bold}$(tput setaf 1)"
readonly bold_blue="${bold}$(tput setaf 4)"

usage ()
{
    cat << EOF
Usage: scot [OPTION]... [-g] [VALUE]
Capture the display.
Unless overriden, capture rectangular selection.

Options:
  -d    capture entire display
  -g    override graphical notifications setting by passing '1' or '0'
  -f    capture to file
  -h    display this help text

Example: scot -nf

Note: Export the 'SCOT_GRAPHICAL' variable to enable graphical notifications.
      Export the 'SCOT_TARGET' variable to set the target for '-f'.
EOF
}

err ()
{
    printf '%berror:%b %s\n' "$bold_red" "$normal" "$*" >&2
}

info ()
{
    printf '%binfo:%b %s\n' "$bold_blue" "$normal" "$*"
}

#
# Handle options
#

[ $SCOT_GRAPHICAL ] && graphical=1

while getopts :hdg:f opt; do
    case "${opt}" in
    h)
        usage; exit
        ;;
    d)
        display=1
        ;;
    g)
        if [ "$OPTARG" = 1 ]; then
            graphical=1
        elif [ "$OPTARG" = 0 ]; then
            graphical=''
        fi
        ;;
    f)
        file=1
        ;;
    :)
        err "Option '$OPTARG' requires an argument"
        printf '%s\n' "Try 'scot -h' for more information."
        exit 1
        ;;
    \?)
        err "Invalid option '$OPTARG'"
        printf '%s\n' "Try 'scot -h' for more information."
        exit 1
        ;;
    esac
done

if [ "$graphical" ]; then
    err ()
    {
        notify-send -u critical "scot" "$*"
    }

    info ()
    {
        notify-send -i "$target" "scot" "$*"
    }
fi

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
