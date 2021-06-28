#!/usr/bin/env bash
#
# Backup the filesystem to an external location using rsync with safety checks,
# intelligent target deduction and succint output.
#

# todo
# 
# experimental macos support (ex: dir exclusions if needed, colour escape codes, utilities used) with uname and get it tested
# test thoroughly on linux, and backup desktop to make sure config and messages and checks work properly (especially free space check and drive model and latest mounted deduction)
# add mention of config file at ~/.config/utilitysh/backup.conf and what it should contain, probably in help text
# add comment that this program is intended to support all FHS compliant systems
# add method of detecting and notifing user of rsync quitting before finishing backup (see commented code or maybe use if statement around rsync command)
# see first answer here for "killall" reminder: <https://superuser.com/questions/1607829/what-does-kill-usr1-1-do>
# make comments proper

#
# User I/O functions 
#
err () {
    echo -e "\e[1;31merror:\033[0m $*" >&2
}

warn () {
    echo -e "\e[1;33mwarn:\033[0m $*"
}

info () {
    echo -e "\e[1;34minfo:\033[0m $*" 
}

conf () {
    local confirm=0
    until [ "$confirm" = "y" -o "$confirm" = "n" -o -z "$confirm" ]; do
        echo -ne "\e[1;36m::\e[0m $* [y/n] "
        read confirm
    done
    [ "$confirm" != "y" -a ! -z "$confirm" ] && exit
}

#
# Act on options
#
while getopts :hlist: opt; do
    case "${opt}" in
        h) 
            echo "Usage: backup [OPTION] [TARGET]"
            echo "Backup the filesystem to an external location."
            echo
            echo "Unless manually set, intelligently determine the target."
            echo
            echo "  -l    log to file instead of stdout"
            echo "  -i    use interactive checks"
            echo "  -t    specify target for the backup"
            echo "  -s    skip confirmation (use at your own peril)"
            echo "  -h    display this help text"
            echo
            echo "Example: backup -lt /mnt/backup/"
            exit
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
# Attempt to determine target unless manually set
#
if [ -z "$targ" ]; then
    # use config file of non-root user
    config="$(grep "${SUDO_USER:-${USER}}" /etc/passwd \
    | cut -d: -f6)/.config/utilitysh/backup.conf" 
    if [ -s "$config" ]; then
        targ="$(realpath "$(cat "$config")")"
    # use latest mounted non-tmpfs drive
    elif [ "$(df --output=source | tail -n 1)" != "tmpfs" ]; then
        targ="$(df --output=source | tail -n 1)"
    else
        err "Could not determine a suitable target"
        echo "Try 'backup -h' for more information."
        exit 1
    fi
fi

#
# Run checks
#
check_root () {
    [ $(df --output=source / | tail -n 1) \
    != $(df --output=source "$targ" | tail -n 1) ]
}

check_space () {
    [ $(df --output=used -k / | tail -n 1) \
    -lt $(df --output=avail -k "$targ" | tail -n 1) ]
}

if [ -e "$(df --output=source "$targ" 2> /dev/null | tail -n 1)" ]; then
    # obtain model of target drive
    target_model="$(lsblk -no MODEL /dev/"$(lsblk -no PKNAME \
    "$(df --output=source "$targ" | tail -n 1)")")"
fi

if [ -z "$interact" ]; then
    if [ $(id -u) != 0 ]; then
        warn "We do not have root privileges"
    fi
    if [ -d "$targ" -a -r "$targ" -a -w "$targ" -a ! -z "$target_model" ]; then
        if ! check_root; then
            warn "Target drive '$target_model' is the root drive"
        fi
        if ! check_space; then
            warn "Target drive '$target_model' has insufficient free space"
        fi
    elif [ -d "$targ" -a -n "$target_model" ]; then
        warn "Target '$targ' is inaccessible"
    elif [ -e "$targ" -o -z "$target_model" ]; then
        warn "Target '$targ' is invalid"
    else
        warn "Target '$targ' does not exist"
    fi
else
    if [ $(id -u) != 0 ]; then
        conf "We do not have root privileges. Proceed anyway?"
    fi
    if [ -d "$targ" -a -r "$targ" -a -w "$targ" -z "$target_model" ]; then
        if ! check_root; then
            conf "Target drive '$target_model' is the root drive. Proceed anyway?"
        fi
        if ! check_space; then
            conf "Target drive '$target_model' has insufficient free space. Proceed anyway?"
        fi
    elif [ -d "$targ" ]; then
        conf "Target '$targ' is inaccessible. Proceed anyway?"
    elif [ -e "$targ" ]; then
        conf "Target '$targ' is invalid. Proceed anyway?"
    else
        conf "Target '$targ' does not exist. Proceed anyway?"
    fi
fi

#
# Confirm or announce target
#
if [ -z "$skip_confirm" ]; then
    if [ -n "$target_model" ]; then
        conf "Backup to '$targ' on '$target_model'?"
    else
        conf "Backup to '$targ'?"
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
    info "Log file is '${PWD}/backup.log'"
    rsync -aHAXv --del / \
    --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/lost+found","/swapfile"} \
    "$targ" &> "backup.log" &
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
