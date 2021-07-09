#!/usr/bin/env bash
#
# ydl-plus: Download media from the internet
#
# Copyright (c) 2021 Emil Overbeck <https://github.com/Swarthe>
# Licensed under the MIT License. See LICENSE.txt for more information.
#

#
# Prompt user
#
echo "1) Download video"
echo "2) Download audio"
echo -n "> "
read type

echo -n "Enter target directory: "
read target
# add leading slash to avoid breaking youtube-dl
[ -n "$target" ] && target+="/"

echo -n "Enter URL: "
read url

#
# Download media
#
case $type in 
    1)
        youtube-dl --add-header 'Cookie:' -o "${target}%(title)s.%(ext)s" "$url"
        ;;
    2)
        youtube-dl --add-header 'Cookie:' -xo "${target}%(title)s.%(ext)s" "$url"
        ;;
    *)
        echo "Invalid input!"
        exit 1
        ;;
esac
