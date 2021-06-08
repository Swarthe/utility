#!/usr/bin/env bash
#
# Backup the filesystem to an external hard drive with rsync.

# Prompt user
echo "1) Backup desktop"
echo "2) Backup laptop"
echo -n "> "
read dev

# Run backup
case $dev in
    1)
        rsync -aHAXv --del / \
        --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/lost+found","/swapfile"} \
        /mnt/desktop-backup/
        ;;
    2)
        rsync -aHAXv --del / \
        --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/lost+found"} \
        /mnt/laptop-backup/
        ;;
    *)
        echo "Invalid input!"
        exit 1
        ;;
esac
