#!/usr/bin/env bash
#
# scot: Capture the display to clipboard or file (intended for window managers)
#
# Copyright (c) 2021 Emil Overbeck <https://github.com/Swarthe>
# Licensed under the MIT License. See LICENSE.txt for more information.
#

#
# User I/O functions 
#
usage () {
    cat << EOF
Usage: scot [OPTION]
Capture the display to clipboard or file.
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

info () {
    echo -e "\e[1;34minfo:\033[0m $*" 
}

err () {
    echo -e "\e[1;31merror:\033[0m $*" >&2
}

#
# Handle options
#
[ "$*" != "${*/--help/}" ] && usage && exit

while getopts :hdgf opt; do
    case "${opt}" in
        h)
            usage; exit
            ;;
        d)
            display="1"
            ;;
        g)
            gui="1"
            # change i/o functions to graphical output
            err () {
                notify-send -u critical "error" "$*"
            }
            info () {
                notify-send -i "$target" "info" "$*"
            }
            ;;
        f)
            file="1"
            ;;
        \?)
            err "Invalid option '$OPTARG'"
            echo "Try 'scot -h' for more information."
            exit 1
            ;;
    esac
done

#
# Take screenshot
#
if [ -z "$file" ]; then
    if [ -z "$display"]; then
        import png:- | xclip -selection clipboard -t image/png
    else
        import -window root png:- | xclip -selection clipboard -t image/png
    fi
else
    # increment filename to avoid overwriting
    if [ -n "$SCOT_TARGET" ]; then
        target="$(realpath "${SCOT_TARGET}/screenshot.png")"
        while [ -e "$target" ]; do
            i=$(($i + 1))
            target="$(realpath "${SCOT_TARGET}/screenshot-${i}.png")"
        done
    else
        target="$(realpath screenshot.png)"
        while [ -e "$target" ]; do
            i=$(($i + 1))
            target="$(realpath screenshot-${i}.png)"
        done
    fi
    if [ -z "$display" ]; then
        import "$target"
    else
        import -window root "$target"
    fi
fi

#
# Announce or notify
#
if [ -n "$gui" ]; then
    if [ -z "$file" ]; then
        info "Screenshot successful"
    elif [ -e "$target" ]; then
        info "Screenshot is '$target'"
    else
        err "Could not save screenshot"
    fi
else
    [ -e "$target" ] && info "Screenshot is '$target'"
fi
