#!/usr/bin/env bash

#Download batch of videos from Youtube as ordered list

#User prompt
echo "1) Download ordered video playlist"
echo "2) Download ordered audio playlist"
echo -n "> "
read format
echo -n "Enter target directory: "
read dir
echo -n "Enter Youtube URL: "
read url

#Target directory correction
if [ "${dir: -1}" != "/" ]; then
  dir+="/"
fi

#Running download
if [ $format == "1" ]; then
  youtube-dl --add-header 'Cookie:' -o "$dir%(playlist_index)s. %(title)s.%(ext)s" "$url"
elif [ $format == "2" ]; then
  youtube-dl --add-header 'Cookie:' -xo "$dir%(playlist_index)s. %(title)s.%(ext)s" "$url"
else
  echo "Invalid input!"
  exit 1
fi
