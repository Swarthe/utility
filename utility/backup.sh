#!/usr/bin/env bash
#
# backup: Backup the filesystem to an external location, assuming FHS compliance
#
# Copyright (c) 2021 Emil Overbeck <https://github.com/Swarthe>
# Licensed under the MIT License. See LICENSE.txt for more information.
#

# todo
# 
# experimental macos support (ex: dir exclusions if needed, colour escape codes, utilities used) with uname and get it tested
# test thoroughly on linux, and backup desktop to make sure BACKUP_TARGET and messages and checks and backup itself work properly (especially free space check and drive model and latest mounted deduction)

#
# User I/O functions 
#
usage () {
    cat << EOF
Usage: backup [OPTION]... [-t] [TARGET]
Backup the filesystem to an external location.
Unless manually set, automatically determine the target.

Options:
  -v    use verbose output
  -l    log to file instead of stdout (implies '-v')
  -i    use interactive checks
  -t    specify target for the backup
  -s    skip all interactive prompts (use at your own peril)
  -h    display this help text

Example: backup -lt /mnt/backup/

Note: Export the 'BACKUP_TARGET' variable to set the default target.
EOF
}

err () {
    echo -e "\e[1;31merror:\033[0m $*" >&2
}

warn () {
    echo -e "\e[1;33mwarn:\033[0m $*"
}

info () {
    echo -e "\e[1;34minfo:\033[0m $*" 
}

ask () {
    local confirm=0
    until [ "$confirm" = "y" -o "$confirm" = "n" -o -z "$confirm" ]; do
        echo -ne "\e[1;36m::\e[0m $* [y/n] "
        read confirm
    done
    [ "$confirm" != "y" -a ! -z "$confirm" ] && exit
}

#
# Handle options
#
[ "$*" != "${*/--help/}" ] && usage && exit

while getopts :hvlist: opt; do
    case "${opt}" in
        h) 
            usage && exit
            ;;
        v)
            verbose=1
            ;;
        l)
            log=1
            ;;
        i)
            interact=1
            ;;
        t)
            target="$(realpath "$OPTARG")"
            
            ;;
        s)
            skip_interact=1
            ;;
        :)
            err "Option '$OPTARG' requires an argument"
            echo "Try 'backup -h' for more information."
            exit 1
            ;;
        \?)
            err "Invalid option '$OPTARG'"
            echo "Try 'backup -h' for more information."
            exit 1
            ;;
    esac
done

#
# Attempt to determine target and related data if needed
#
latest_source="$(df --output=source | tail -n 1)"
target_target="$(df --output=target "$target" | tail -n 1)"

if [ -z "$target" ]; then
    if [ -n "$BACKUP_TARGET" ]; then
        target="$(realpath "$BACKUP_TARGET")"
    # use latest mounted real filesystem
    elif [ -e "$latest_source" ]; then
        target="$(realpath "$latest_source")"
    else
        err "Could not determine a suitable target"
        echo "Try 'backup -h' for more information."
        exit 1
    fi
fi

target_model="$(lsblk -no MODEL /dev/"$(lsblk -no PKNAME \
"$(df --output=source "$target" 2> /dev/null | tail -n 1)" \
2> /dev/null)" 2> /dev/null)"

#
# Run checks
#
check_root () {
    [ "$target_target" != "/" ]
}

check_space () {
    [ $(df --output=used -k / | tail -n 1) \
    -lt $(df --output=avail -k "$target" | tail -n 1) ]
}

if [ -z "$interact" ]; then
    if [ "$(id -u)" != "0" ]; then
        warn "We do not have root privileges"
    fi
    if [ -d "$target" -a -w "$target" -a -n "$target_model" ]; then
        if ! check_root; then
            warn "Target drive '$target_model' is the root drive"
            target_is_root=1
        fi
        if ! check_space; then
            warn "Target drive '$target_model' has insufficient free space"
        fi
    elif [ -d "$target" -a -n "$target_model" ]; then
        warn "Target '$target' is inaccessible"
    elif [ -e "$target" ]; then
        warn "Target '$target' is invalid"
    else
        warn "Target '$target' does not exist"
    fi
else
    if [ "$(id -u)" != "0" ]; then
        ask "We do not have root privileges. Proceed anyway?"
    fi
    if [ -d "$target" -a -w "$target" -a -n "$target_model" ]; then
        if ! check_root; then
            ask "Target drive '$target_model' is the root drive. Proceed anyway?"
            target_is_root=1
        fi
        if ! check_space; then
            ask "Target drive '$target_model' has insufficient free space. Proceed anyway?"
        fi
    elif [ -d "$target" -a -n "$target_model" ]; then
        ask "Target '$target' is inaccessible. Proceed anyway?"
    elif [ -e "$target" ]; then
        ask "Target '$target' is invalid. Proceed anyway?"
    else
        ask "Target '$target' does not exist. Proceed anyway?"
    fi
fi

#
# Confirm or announce target
#
if [ -z "$skip_interact" ]; then
    if [ -n "$target_model" ]; then
        ask "Backup to '$target' on '$target_model'?"
    else
        ask "Backup to '$target'?"
    fi
else
    if [ -n "$target_model" ]; then
        info "Target is '$target' on '$target_model'"
    else
        info "Target is '$target'"
    fi
fi

#
# Run backup
#
if [ -z "$verbose" -a -z "$log" ]; then
    syncr () {
        rsync -aHAX --info=progress2 --delete / \
        --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/lost+found","/swapfile"} \
        "$target"
    }
else
    syncr () {
        rsync -aHAXv --delete / \
        --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/lost+found","/swapfile"} \
        "$target"
    }

fi

clean () {
    if [ -z "$skip_interact" -a -z "$target_is_root" -a -n "$target_model" ]; then
        ask "Unmount target drive '$target_model' at '$target_target'?"
        umount "$target_target"
    fi
}

if [ -z "$log" ]; then
    syncr && clean
else
    if [ -w . ]; then
        syncr &> "backup.log" &
        rsync_pid=$!
        info "Log file is '"$(realpath backup.log)"'"
    else
        syncr &> /dev/null &
        rsync_pid=$!
        err "Could not create log file"
    fi
    while kill -0 $rsync_pid 2> /dev/null; do
        for i in / - \\ \|; do 
            echo -ne "\r\e[K\e[1;34minfo:\033[0m Backup in progress $i"
            sleep 0.1
        done
    done
    echo
    if wait $rsync_pid; then
        info "Backup complete"
        clean
    else
        err "Backup failed"
        [ -e backup.log ] && echo "See 'backup.log' for more information."
    fi
fi
