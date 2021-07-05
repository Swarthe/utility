#!/usr/bin/env bash
#
# backup: Backup the filesystem to an external location
#
# Licensed under the MIT License. See LICENSE.txt for more information.
#

# todo
# 
# experimental macos support (ex: dir exclusions if needed, colour escape codes, utilities used) with uname and get it tested
# test thoroughly on linux, and backup desktop to make sure config and messages and checks work properly (especially free space check and drive model and latest mounted deduction)
# add mention of config file at $XDG_CONFIG_HOME/backup.conf and what it should contain, probably in help text
# add comment that this program is intended to support all FHS compliant systems
# add method of detecting and notifing user of rsync quitting before finishing backup (see commented code or maybe use if statement around rsync command)
# see first answer here for "killall" reminder: <https://superuser.com/questions/1607829/what-does-kill-usr1-1-do>
# add check that filesystems are the same (or compatible if possible)
# see if we can use rsync --progress to display progress bar, maybe even with log option
# make comments proper

#
# User I/O functions 
#
usage () {
    cat <<EOF
Usage: backup [OPTION]... [-t] [TARGET]
Backup the filesystem to an external location.
Unless manually set, automatically determine the target.

Options:
  -l    log to file instead of stdout
  -i    use interactive checks
  -t    specify target for the backup
  -s    skip confirmation (use at your own peril)
  -h    display this help text

Example: backup -lt /mnt/backup/
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
[ "$1" = "--help" ] && usage && exit

while getopts :hlist: opt; do
    case "${opt}" in
        h) 
            usage && exit
            ;;
        l)
            log=1
            ;;
        i)
            interact=1
            ;;
        t)
            targ="$(realpath "$OPTARG")"
            
            ;;
        s)
            skip_confirm=1
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
# Attempt to determine target if needed and its metadata
#
config_path="$(grep "${SUDO_USER:-${USER}}" /etc/passwd \
| cut -d: -f6)/"${XDG_CONFIG_HOME:-.config}"/utility/backup.conf" 

latest_source="$(df --output=source | tail -n 1)"

if [ -z "$targ" ]; then
    if [ -s "$config_path" ]; then
        targ="$(realpath "$(cat "$config_path")")"
    # use latest mounted real filesystem
    elif [ -e "$latest_source" ]; then
        targ="$latest_source"
    else
        err "Could not determine a suitable target"
        echo "Try 'backup -h' for more information."
        exit 1
    fi
fi

target_model="$(lsblk -no MODEL /dev/"$(lsblk -no PKNAME \
"$(df --output=source "$targ" 2> /dev/null | tail -n 1)" \
2> /dev/null)" 2> /dev/null)"

#
# Run checks
#
check_root () {
    [ "$(df --output=target "$targ" | tail -n 1)" != "/" ]
}

check_space () {
    [ $(df --output=used -k / | tail -n 1) \
    -lt $(df --output=avail -k "$targ" | tail -n 1) ]
}

if [ -z "$interact" ]; then
    if [ "$(id -u)" != "0" ]; then
        warn "We do not have root privileges"
    fi
    if [ -d "$targ" -a -w "$targ" -a -n "$target_model" ]; then
        if ! check_root; then
            warn "Target drive '$target_model' is the root drive"
        fi
        if ! check_space; then
            warn "Target drive '$target_model' has insufficient free space"
        fi
    elif [ -d "$targ" -a -n "$target_model" ]; then
        warn "Target '$targ' is inaccessible"
    elif [ -e "$targ" ]; then
        warn "Target '$targ' is invalid"
    else
        warn "Target '$targ' does not exist"
    fi
else
    if [ "$(id -u)" != "0" ]; then
        ask "We do not have root privileges. Proceed anyway?"
    fi
    if [ -d "$targ" -a -w "$targ" -a -n "$target_model" ]; then
        if ! check_root; then
            ask "Target drive '$target_model' is the root drive. Proceed anyway?"
        fi
        if ! check_space; then
            ask "Target drive '$target_model' has insufficient free space. Proceed anyway?"
        fi
    elif [ -d "$targ" -a -n "$target_model" ]; then
        ask "Target '$targ' is inaccessible. Proceed anyway?"
    elif [ -e "$targ" ]; then
        ask "Target '$targ' is invalid. Proceed anyway?"
    else
        ask "Target '$targ' does not exist. Proceed anyway?"
    fi
fi

#
# Confirm or announce target
#
if [ -z "$skip_confirm" ]; then
    if [ -n "$target_model" ]; then
        ask "Backup to '$targ' on '$target_model'?"
    else
        ask "Backup to '$targ'?"
    fi
else
    if [ -n "$target_model" ]; then
        info "Target is '$targ' on '$target_model'"
    else
        info "Target is '$targ'"
    fi
fi

#
# Run backup
#
if [ -z "$log" ]; then
    rsync -aHAXv --del / \
    --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/lost+found","/swapfile"} \
    "$targ"
else
    rsync -aHAXv --del / \
    --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/lost+found","/swapfile"} \
    "$targ" &> "backup.log" &
    [ -w . ] && info "Log file is '"$(realpath backup.log)"'"
    while killall -q -0 rsync; do
        for i in / - \\ \|; do 
            echo -ne "\r\e[K\e[1;34minfo:\033[0m Backup in progress $i"
            sleep 0.1
        done
    done
    echo
    # if grep "rsync error" "$(tail -n 5 backup.log)"; then
    #     err "backup could not complete"
    # else
        info "Backup complete"
    # fi
fi
