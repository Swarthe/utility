#!/usr/bin/env bash
#
# backup: Synchronise the filesystem to an external location with rsync, assuming FHS compliance
#
# Copyright (c) 2021 Emil Overbeck <https://github.com/Swarthe>
#
# Subject to the MIT License. See LICENSE.txt for more information.
#

# todo
# 
# experimental and automatic macos support (ex: dir exclusions if needed, colour escape codes, utilities used) with uname and get it tested
# test thoroughly on linux, and backup desktop to make sure BACKUP_TARGET and messages and checks and backup itself work properly (especially free space check and drive model and latest mounted deduction)

#
# User I/O functions and variables
#
usage ()
{
    cat << EOF
Usage: backup [OPTION]... [-t] [TARGET]
Synchronise the filesystem to an external location.
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

if [ $(tput colors) -ge 256 ]; then
    readonly bold_red="\e[1;31m"
    readonly bold_yellow="\e[1;33m"
    readonly bold_blue="\e[1;34m"
    readonly bold_cyan="\e[1;36m"
    readonly normal="\033[0m"
fi

err ()
{
    printf "%berror:%b $*\n" "$bold_red" "$normal" >&2
}

warn ()
{
    printf "%bwarn:%b $*\n" "$bold_yellow" "$normal" >&2
}

info ()
{
    printf "%binfo:%b $*\n" "$bold_blue" "$normal"
}

ask ()
{
    local confirm
    until [ "$confirm" = "y" -o "$confirm" = "n" ]; do
        printf "%b::%b $* [y/n] " "$bold_cyan" "$normal"
        read -r confirm
    done
    [ "$confirm" != "y" ] && return 1 || return 0
}

#
# Handle options
#
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
        printf '%s\n' "Try 'backup -h' for more information."
        exit 1
        ;;
    \?)
        err "Invalid option '$OPTARG'"
        printf '%s\n' "Try 'backup -h' for more information."
        exit 1
        ;;
    esac
done

#
# Attempt to determine target and related data if needed
#
latest_source="$(df --output=source | tail -n 1)"

if [ -z "$target" ]; then
    if [ "$BACKUP_TARGET" ]; then
        target="$(realpath "$BACKUP_TARGET")"
    # use latest mounted real filesystem
    elif [ -e "$latest_source" ]; then
        target="$(realpath "$latest_source")"
    else
        err "Could not determine a suitable target"
        printf '%s\n' "Try 'backup -h' for more information."
        exit 1
    fi
fi

[ -e "$target" ] \
    && target_source="$(df --output=source "$target" | tail -n 1)"

[ "$target_source" ] \
    && target_target="$(df --output=target "$target" | tail -n 1)"

[ "$target_source" ] \
    && target_model="$(lsblk -no MODEL /dev/"$(lsblk -no PKNAME "$target_source")")"

#
# Run checks
#
check_root ()
{
    [ "$target_target" != "/" ]
}

check_space ()
{
    [ $(df --output=used -k / | tail -n 1) \
    -lt $(df --output=size -k "$target" | tail -n 1) ]
}

if [ -z "$interact" ]; then
    if [ "$(id -u)" != "0" ]; then
        warn "We do not have root privileges"
    fi

    if [ -d "$target" -a -w "$target" -a "$target_model" ]; then
        if ! check_root; then
            warn "Target drive '$target_model' is the root drive"
            target_is_root=1
        fi

        if ! check_space; then
            warn "Target drive '$target_model' has insufficient free space"
        fi
    elif [ -d "$target" -a "$target_model" ]; then
        warn "Target '$target' is inaccessible"
    elif [ -e "$target" ]; then
        warn "Target '$target' is invalid"
    else
        warn "Target '$target' does not exist"
    fi
else
    if [ "$(id -u)" != "0" ]; then
        ask "We do not have root privileges. Proceed anyway?" \
            || exit 0
    fi

    if [ -d "$target" -a -w "$target" -a "$target_model" ]; then
        if ! check_root; then
            ask "Target drive '$target_model' is the root drive. Proceed anyway?" \
                || exit 0
            target_is_root=1
        fi

        if ! check_space; then
            ask "Target drive '$target_model' has insufficient free space. Proceed anyway?" \
                || exit 0
        fi
    elif [ -d "$target" -a "$target_model" ]; then
        ask "Target '$target' is inaccessible. Proceed anyway?" \
            || exit 0
    elif [ -e "$target" ]; then
        ask "Target '$target' is invalid. Proceed anyway?" \
            || exit 0
    else
        ask "Target '$target' does not exist. Proceed anyway?" \
            || exit 0
    fi
fi

#
# Confirm or announce target
#
if [ -z "$skip_interact" ]; then
    if [ "$target_model" ]; then
        ask "Backup to '$target' on '$target_model'?" \
            || exit 0
    else
        ask "Backup to '$target'?" \
            || exit 0
    fi
else
    if [ "$target_model" ]; then
        info "Target is '$target' on '$target_model'" \
            || exit 0
    else
        info "Target is '$target'" \
            || exit 0
    fi
fi

#
# Run backup
#
syncr ()
{
    if [ -z "$verbose" -a -z "$log" ]; then
        rsync -aHAX --info=progress2 --delete / \
        --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/lost+found","/swapfile"} \
        "$target"
    else
        rsync -aHAXv --delete / \
        --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/lost+found","/swapfile"} \
        "$target"
    fi
}

clean ()
{
    if [ -z "$skip_interact" -a -z "$target_is_root" -a "$target_model" ]; then
        ask "Unmount target drive '$target_model' at '$target_target'?" \
            || exit 0
        umount "$target_target"
    fi
}

if [ -z "$log" ]; then
    syncr && clean
else
    if [ -w . ]; then
        syncr &> "backup.log" &
        rsync_pid=$!
        info "Log file is '$(realpath backup.log)'"
    else
        syncr &> /dev/null &
        rsync_pid=$!
        err "Could not create log file"
    fi

    while kill -0 $rsync_pid 2> /dev/null; do
        for i in . .. ...; do
            # the escape code resets the line
            printf "\r\e[K%binfo:%b Backup in progress%b" "$bold_blue" \
                                                          "$normal" \
                                                          "$i"
            sleep 0.5
        done
    done

    printf "\n"

    if wait $rsync_pid; then
        info "Backup successful" && clean
    else
        err "Backup failed"
        [ -e backup.log ] \
            && printf '%s\n' "See 'backup.log' for more information."
    fi
fi
