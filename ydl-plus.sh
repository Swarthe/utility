#!/usr/bin/env bash

#Download video or audio from Youtube with clean filenames

#User prompt
echo "1) Download video"
echo "2) Download audio"
echo -n "> "
read form
echo -n "Enter target directory: "
read dir
echo -n "Enter Youtube URL: "
read url

#Target directory correction
if [ "${dir: -1}" != "/" ]; then
  dir+="/"
fi

#Running download with youtube-dl
if [ "$form" == "1" ]; then
  youtube-dl --add-header 'Cookie:' -o "$dir%(title)s.%(ext)s" "$url"
elif [ "$form" == "2" ]; then
  youtube-dl --add-header 'Cookie:' -xo "$dir%(title)s.%(ext)s" "$url"
else
  echo "Invalid input!"
  exit 1
fi
