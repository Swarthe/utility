#!/usr/bin/env bash
#
# ydl: Download video or audio media from the internet in an organised
#      fashion using youtube-dl
#
# Copyright (c) 2021 Emil Overbeck <https://github.com/Swarthe>
#
# Subject to the MIT License. See LICENSE.txt for more information.
#

# TODO: maybe add this as feature
#
# Cool example command for audio playlists from YouTube ' - Topic' channels
# which don't have artists name in title:
#
# youtube-dl --add-header 'Cookie:' --playlist-start $start --playlist-end \
# $end -xo "%(creator)s - %(title)s.%(ext)s" "$url"
#
# maybe maybe add env variables for default target and creator setting and other
#
# make it possible to specify several URLs in a row without having to pass
# options repeatedly
#
# add possibility to add creator name to metadata as 'Artist' tag, with filename
# as '[artist] - [title]', and 'Title' tag as '[title]'
#

#
# User I/O functions and variables
#

readonly normal="$(tput sgr0)"
readonly bold="$(tput bold)"
readonly bold_red="${bold}$(tput setaf 1)"

usage ()
{
    cat << EOF
Usage: ydl [OPTION]... [URL]... [-t] [TARGET]
Download video or audio media form the internet.

Options:
  -a    download as audio from the specified URL
  -t    specify the target directory for download
  -c    prepend the creator's name to the filename
  -h    display this help text

Example: ydl -a [URL] -t ~/video



Note: Media is downloaded as video by default.
EOF
}

err ()
{
    printf '%berror:%b %s\n' "$bold_red" "$normal" "$*" >&2
}

#
# Handle options
#

while getopts :ht:ac opt; do
    case "${opt}" in
    h)
        usage; exit
        ;;
    t)
        # add leading slash to avoid breaking youtube-dl
        target="$(realpath "$OPTARG")/"
        ;;
    a)
        format='x'
        ;;
    c)
        creator="%(creator)s - "
        ;;
    \?)
        err "Invalid option '$OPTARG'"
        printf '%s\n' "Try 'ydl -h' for more information."
        exit 1
        ;;
    esac
done

shift $((OPTIND-1))

#
# Run the download
#

if [ "$*" ]; then
    # unquoted '$*' variable is very dangerous, but youtube-dl treats it as only
    # one URL otherwise
    youtube-dl --add-header 'Cookie:' -${format}o \
    "${target}${creator}%(title)s.%(ext)s" $*
else
    err "Missing URL"
    printf '%s\n' "Try 'ydl -h' for more information."
fi
