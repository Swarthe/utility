#!/usr/bin/sh

proc_n=$(($(grep owner_pid /proc/asound/card*/pcm*/sub*/status | wc -l) - 1))

if [ $proc_n -le 0 ]; then
    echo ""
else
    echo " $proc_n"
fi
