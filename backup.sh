#!/usr/bin/env bash

#Backup filesystem to external hard drive

#User prompt
echo "1) Backup desktop"
echo "2) Backup laptop"
echo -n "> "
read backup

#Running backup with rsync
if [ $backup == "1" ]; then
  rsync -aHAXv --del / --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/lost+found","/swapfile"} \
  /mnt/desktop-backup/
elif [ $backup == "2" ]; then
  rsync -aHAXv --del / --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/lost+found"} \
  /mnt/laptop-backup/
else
  echo "Invalid input!"
  exit 1
fi
