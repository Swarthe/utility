#!/usr/bin/env bash
#
# Backup the filesystem to an external location using rsync, with safety checks
# and intelligent target deduction.
#

# todo
# 
# experimental macos support (ex: dir exclusions if needed, colour escape codes) with uname and get it tested
# test thoroughly on linux, and backup desktop to make sure config and messages and checks work properly (especially free space check)
# add mention of config file at ~/.config/utilitysh/backup.conf and what it should contain, probably in help text
# add comment that this program is intended to support all FHS compliant systems
# add method of detecting and notifing user of rsync quitting before finishing backup (see commented code)
# make comments proper

#
# User message functions 
#
err () {
    echo -e "\e[31merror:\033[0m $*" >&2
}

warn () {
    echo -e "\e[33mwarning:\033[0m $*"
}

inf () {
    echo -e "\e[32mbackup:\033[0m $*" 
}

#
# Act on options
#
while getopts :hlst: opt; do
    case "${opt}" in
        h) 
            echo "Usage: backup [OPTION] [TARGET]"
            echo "Backup the filesystem to an external location."
            echo
            echo "Unless manually set, intelligently determine the target."
            echo
            echo "  -l    log to file instead of stdout"
            echo "  -s    skip all checks (use at your own peril)"
            echo "  -t    specify target for the backup"
            echo "  -h    display this help text"
            echo
            echo "Example: backup -lt /mnt/backup/"
            exit
            ;;
        l)
            log=1
            ;;
        s)
            skip=1
            ;;
        t)
            targ="$OPTARG"
            skip_confirm=1
            ;;
        :)
            err "option '$OPTARG' requires an argument"
            echo "Try 'backup -h' for more information."
            exit 1
            ;;
        \?)
            err "invalid option '$OPTARG'"
            echo "Try 'backup -h' for more information."
            exit 1
            ;;
    esac
done

#
# Intelligently determine target unless manually set
#
if [ -z "$targ" ]; then
    if [ -s "$(cat "$(grep "${SUDO_USER:-${USER}}" /etc/passwd \
    | cut -d: -f6)/.config/utilitysh/backup.conf" 2> /dev/null)" ]; then
        targ="$(cat "$(grep "${SUDO_USER:-${USER}}" /etc/passwd \
        | cut -d: -f6)/.config/utilitysh/backup.conf" 2> /dev/null)"
    elif [ -f /etc/mtab ]; then
        targ="$(tail -n 1 /etc/mtab | awk '{print $2}')"
    else
        err "could not determine target; this system may be unsupported"
        err "please contact the author of this program"
        exit 1
    fi
fi

#
# Checks
#
ask () {
    local confirm=0
    until [ "$confirm" = "y" -o "$confirm" = "n" -o -z "$confirm" ]; do
        echo -ne "\e[34m::\e[0m $* [y/n] "
        read confirm
    done
    if [ "$confirm" != "y" -a ! -z "$confirm" ]; then
        exit
    fi
}

if [ -z "$skip" ]; then
    if [ $(id -u) != 0 ]; then
        ask "Backup is not running as root. Proceed anyway?"
    fi
    if [ ! -d "$targ" -o ! -w "$targ" ]; then
        ask "Target '$(lsblk -no MODEL)' is inaccessible. Proceed anyway?"
        skip_free=1
    fi
    if [ $(df --output=source / | tail -n 1) \
    = $(df --output=source "$targ" | tail -n 1) ]; then
        ask "Target '$(lsblk -no MODEL)' is the root drive. Proceed anyway?"
    fi
    if [ -z "$skip_free" ]; then
        if [ $(df --output=used -k / | tail -n 1) \
        -gt $(df --output=avail -k "$targ" | tail -n 1) ]; then
            ask "Target '$(lsblk -no MODEL)' has insufficient free space. Proceed anyway?"
        fi
    fi
    if [ -z "$skip_confirm" ]; then
        ask "Backup to '$(lsblk -no MODEL)' at '$targ'?"
    fi
fi

#
# Run backup
#
if [ -n "$skip" ]; then
    warn "target is '$(lsblk -no MODEL)' at '$targ'"
fi

if [ -z "$log" ]; then
    rsync -aHAXv --del / \
    --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/lost+found","/swapfile"} \
    "$targ"
else
    inf "log file is '${PWD}/backup.log'"
    rsync -aHAXv --del / \
    --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/lost+found","/swapfile"} \
    "$targ" &> "backup.log" &
    while killall -q -0 rsync; do
        for i in / - \\ \|; do 
            echo -ne "\r\e[K\e[32mbackup:\033[0m backup in progress $i"
            sleep 0.1
        done
    done
    echo
    # if grep "rsync error" "$(tail -n 5 backup.log)"; then
    #     err "backup could not complete"
    # else
        inf "backup complete"
    # fi
fi
