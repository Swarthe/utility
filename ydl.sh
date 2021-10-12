#!/usr/bin/env bash
#
# ydl: Download video or audio media from the internet with metadata in an
#      organised fashion using youtube-dl
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
# maybe maybe add env variables for default target (transient for us) and
# creator setting and other
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
Usage: ydl [OPTION]... [-t] [TARGET] [URL]...
Download video or audio media form the internet.

Options:
  -a    download media as audio
  -t    specify the target directory for the download
  -c    prepend the creator's name to the filename
  -h    display this help text

Example: ydl -ct ~/video [URL]

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

# default youtube-dl options for video
format='--embed-subs --all-subs'

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
        # youtube-dl cannot embed subtitles in audio files
        format='-x'
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
args=("$@")

#
# Run the download
#

if [ "${args[@]}" ]; then
    youtube-dl --embed-thumbnail --add-metadata $format --add-header 'Cookie:' \
    -io "${target}${creator}%(title)s.%(ext)s" "${args[@]}"
else
    err "Missing URL"
    printf '%s\n' "Try 'ydl -h' for more information."
fi
