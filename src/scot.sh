#!/usr/bin/env bash
#
# scot: Capture the display to clipboard or file using ImageMagick
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

Options:
  -d    capture the entire display
  -t    capture to file in '\$SCOT_TARGET'
  -g    specify 'on' to enable graphical user I/O; specify 'off' to disable
          (overrides '\$UTILITY_GRAPHICAL')
  -h    display this help text

Example: scot -df

Environment variables:
  SCOT_TARGET           set the target directory for '-f'
  UTILITY_GRAPHICAL     '1' to enable graphical user I/O

Note: By default, a rectangular selection is captured.
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

gerr ()
{
    notify-send -i \
    /usr/share/icons/Papirus-Dark/32x32/apps/gnome-screenshot.svg \
    -u critical 'scot' "$*"
}

ginfo ()
{
    notify-send -i "$real_target" 'scot' "$*"
}

#
# Handle options
#

while getopts :hdg:f opt; do
    case "${opt}" in
    h)
        usage; exit
        ;;
    d)
        display=1
        ;;
    g)
        case "$OPTARG" in
        on)
            graphical_override=1
            ;;
        off)
            graphical_override=0
            ;;
        *)
            err "Invalid argument '$OPTARG' for option 'g'"
            printf '%s\n' "Try 'scot -h' for more information."
            exit 1
            ;;
        esac
        ;;
    f)
        target="$(realpath "$SCOT_TARGET")"
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

shift $((OPTIND-1))
args=("$@")

# do not permit extra arguments
if [ "$args" ]; then
    for c in "${args[@]}"; do
         err "Invalid argument '$c'"
    done

    printf '%s\n' "Try 'scot -h' for more information."
    exit 1
fi

# Determine whether or not to use graphical output
case "$graphical_override" in
1)
    graphical=1
    ;;
0)
    ;;
*)
    [ "$UTILITY_GRAPHICAL" = 1 ] && graphical=1
    ;;
esac

#
# Take the screenshot
#

if [ "$target" ]; then
    real_target="${target}/screenshot.png"

    # increment filename to avoid overwriting
    while [ -e "$real_target" ]; do
        i=$((i + 1))
        real_target="${target}/screenshot-${i}.png"
    done

    if [ "$display" ]; then
        import -window root "$real_target" 2> /dev/null
    else
        import "$real_target" 2> /dev/null
    fi
else
    if [ "$display" ]; then
        import -window root png:- | xclip -selection clipboard -t image/png
    else
        import png:- | xclip -selection clipboard -t image/png
    fi

fi

#
# Announce or notify
#

if [ $graphical -a "$target" ]; then
    if [ -e "$real_target" ]; then
        ginfo "Screenshot is '$real_target'"
    else
        gerr "Could not save screenshot"
    fi
elif [ "$target" ]; then
    if [ -e "$real_target" ]; then
        info "Screenshot is '$real_target'"
    else
        err "Could not save screenshot"
    fi
fi
