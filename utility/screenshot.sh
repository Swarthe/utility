#!/usr/bin/env bash
#
# screenshot: Capture the display to clipboard or file
#
# Licensed under the MIT License. See LICENSE.txt for more information.
#

#
# User I/O functions 
#
usage () {
    cat <<EOF
by default, capture rectangular slection

  -d    capture entire display
  -n    use graphical notifications
  -f    capture to file
  -h    display this help text
EOF
}

info () {
    echo -e "\e[1;34minfo:\033[0m $*" 
}

err () {
    echo -e "\e[1;31merror:\033[0m $*" >&2
}

n_info () {
    notify-send -i "${PWD}/screenshot"${i}".png" "info" "$*"
}

n_err () {
    notify-send -u critical "error" "$*"
}

#
# Handle options
#
[ "$1" = "--help" ] && usage && exit

while getopts :hdnf opt; do
    case "${opt}" in
        h)
            usage; exit
            ;;
        d)
            display="1"
            ;;
        n)
            notify="1"
            ;;
        f)
            file="1"
            ;;
        \?)
            err "Invalid option '$OPTARG'"
            echo "Try 'screenshot -h' for more information."
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
    while [ -e "screenshot"${i}".png" ]; do
        i=$(($i + 1))
    done
    if [ -z "$display" ]; then
        import screenshot"${i}".png
    else
        import -window root screenshot"${i}".png
    fi
fi

#
# Announce or notify
#
if [ -n "$notify" ]; then
    if [ -z "$file" ]; then
        n_info "Screenshot successful" # maybe add icon if possible
    elif [ -e "screenshot"${i}".png" ]; then
        n_info "Screenshot is '"$(realpath screenshot"${i}".png)"'"
    else
        n_err "Could not save screenshot"
    fi
else
    [ -e "screenshot"${i}".png" ] && info "Screenshot is '"$(realpath screenshot"${i}".png)"'"
fi
