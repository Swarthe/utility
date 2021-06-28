#!/usr/bin/env bash
#
# Download media with youtube-dl and extra features.
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
if [ "${dir: -1}" != "/" ]; then
    dir+="/"
fi

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
