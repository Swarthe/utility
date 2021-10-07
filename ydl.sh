#!/usr/bin/env bash
#
# ydl: Download video or audio media from the internet in an organised
#      fashion with youtube-dl
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

#
# User I/O functions and variables
#

readonly normal="$(tput sgr0)"
readonly bold="$(tput bold)"
readonly bold_red="${bold}$(tput setaf 1)"

usage ()
{
    cat << EOF
Usage: ydl [OPTION]... [URL] [-t] [TARGET]
Download video or audio media form the internet.

Options:
  -v    download video from the specified URL
  -a    download audio from the specified URL
  -t    specify the target directory for download
  -c    prepend the creator's name to the filename
  -h    display this help text

Example: ydl -a [URL] -t ~/video

Note: You can pass the download options with an argument several times to
      download from multiple different URLs sequentially.
EOF
}

err ()
{
    printf '%berror:%b %s\n' "$bold_red" "$normal" "$*" >&2
}

#
# Handle options
#

while getopts :ht:v:a:c opt; do
    case "${opt}" in
    h)
        usage; exit
        ;;
    t)
        # add leading slash to avoid breaking youtube-dl
        target="$(realpath "$OPTARG")/"
        ;;
    v)
        url="$OPTARG"
        ;;
    a)
        url="$OPTARG"
        format='x'
        ;;
    c)
        creator="%(creator)s - "
        ;;
    :)
        err "Option '$OPTARG' requires an argument"
        printf '%s\n' "Try 'backup -h' for more information."
        exit 1
        ;;
    \?)
        err "Invalid option '$OPTARG'"
        printf '%s\n' "Try 'backup -h' for more information."
        exit 1
        ;;
    esac
done

#
# Run the download
#
if [ $url ]; then
    youtube-dl --add-header 'Cookie:' -${format}o \
    "${target}${creator}%(title)s.%(ext)s" "$url"
else
    err "A valid URL must be passed with '-v' or '-a'"
    printf '%s\n' "Try 'backup -h' for more information."
fi
