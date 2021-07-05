#!/usr/bin/env bash
#
# ydl-plus: Download media from the internet
#
# Licensed under the MIT License. See LICENSE.txt for more information.
#

#
# Prompt user
#
echo "1) Download video"
echo "2) Download audio"
echo -n "> "
read form

echo -n "Enter target directory: "
read dir

echo -n "Enter URL: "
read url

#
# Correct target directory if necessary
#
[ "${dir: -1}" != "/" ] && dir+="/"

#
# Download media
#
case $form in 
    1)
        youtube-dl --add-header 'Cookie:' -o "$dir%(title)s.%(ext)s" "$url"
        ;;
    2)
        youtube-dl --add-header 'Cookie:' -xo "$dir%(title)s.%(ext)s" "$url"
        ;;
    *)
        echo "Invalid input!"
        exit 1
        ;;
esac
