#!/usr/bin/env bash

#Backup filesystem to external hard drive

#User prompt
echo "1) Backup desktop"
echo "2) Backup laptop"
echo -n "> "
read dev

#Running backup with rsync
if [ "$dev" == "1" ]; then
  rsync -aHAXv --del / --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/lost+found","/swapfile"} \
  /mnt/desktop-backup/
elif [ "$dev" == "2" ]; then
  rsync -aHAXv --del / --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/lost+found"} \
  /mnt/laptop-backup/
else
  echo "Invalid input!"
  exit 1
fi
