#!/usr/bin/env bash
#
# backup: Synchronise the filesystem to an external location using rsync,
#         assuming FHS compliance
#
# If using the BACKUP_TARGET or UTILITY_GRAPHICAL environment variables, you can
# configure sudo to preserve them by adding the following to your sudoers file:
#
#   Defaults env_keep += "BACKUP_TARGET UTILITY_GRAPHICAL"
#
# Copyright (c) 2021 Emil Overbeck <https://github.com/Swarthe>
#
# Subject to the MIT License. See LICENSE.txt for more information.
#
# This software is IN DEVELOPMENT and you may PERMANENTLY lose data if you are
# not careful. Please report bugs at <https://github.com/Swarthe/utility>.
#

#
# User I/O functions and variables
#

readonly normal="$(tput sgr0)"
readonly clear_line="$(tput cr && tput el 1)"
readonly bold="$(tput bold)"
readonly bold_red="${bold}$(tput setaf 1)"
readonly bold_yellow="${bold}$(tput setaf 3)"
readonly bold_blue="${bold}$(tput setaf 4)"
readonly bold_cyan="${bold}$(tput setaf 6)"

usage ()
{
    cat << EOF
Usage: backup [OPTION]... [-s] [VALUE] [-t] [TARGET]
Synchronise the filesystem to an external location.

Options:
  -v    use verbose output
  -l    log to a file instead of stdout (implies '-v')
  -t    specify the backup target location (overrides '\$BACKUP_TARGET')
  -s    specify what safety features to skip (use at your own peril); 'prompt'
          to skip prompts, 'check' to skip checks, 'all' to skip everything
  -g    specify 'on' to enable graphical user I/O; specify 'off' to disable
          (overrides '\$UTILITY_GRAPHICAL')
  -h    display this help text

Example: backup -lt /mnt/backup/

Environment variables:
  BACKUP_TARGET         set the backup target location
  UTILITY_GRAPHICAL     '1' to enable graphical user I/O

Note: Unless manually set, we attempt to automatically determine the target.
EOF
}

err ()
{
    printf '%berror:%b %s\n' "$bold_red" "$normal" "$*" >&2
}

warn ()
{
    printf '%bwarn:%b %s\n' "$bold_yellow" "$normal" "$*"
}

info ()
{
    printf '%binfo:%b %s\n' "$bold_blue" "$normal" "$*"
}

ask ()
{
    local confirm

    until [ "$confirm" = "y" -o "$confirm" = "n" ]; do
        printf '%b::%b %s [y/n] ' "$bold_cyan" "$normal" "$*"
        read -r confirm
    done

    if [ "$confirm" = "y" ]; then
        return 0
    else
        return 1
    fi
}

gerr ()
{
    notify-send -i /usr/share/icons/Papirus-Dark/22x22/actions/backup.svg \
    -u critical 'backup' "$*"
}

ginfo ()
{
    notify-send -i /usr/share/icons/Papirus-Dark/22x22/actions/backup.svg \
    'backup' "$*"
}

gask ()
{
    zenity  --question \
    --window-icon=/usr/share/icons/Papirus-Dark/22x22/actions/backup.svg \
    --title 'backup' \
    --text "$*"
}

#
# Handle options
#

while getopts :hvlis:t:g: opt; do
    case "${opt}" in
    h)
        usage; exit
        ;;
    v)
        verbose=1
        ;;
    l)
        log=1
        ;;
    t)
        target="$(realpath "$OPTARG")"
        ;;
    s)
        case "$OPTARG" in
        prompt)
            skip_interact=1
            ;;
        check)
            skip_check=1
            ;;
        all)
            skip_interact=1; skip_check=1
            ;;
        *)
            err "Invalid argument '$OPTARG' for option 's'"
            printf '%s\n' "Try 'backup -h' for more information."
            exit 1
            ;;
        esac
        ;;
    g)
        case "$OPTARG" in
        on)
            graphical_override=1
            ;;
        off)
            graphical_override=0
            ;;
        *)
            err "Invalid argument '$OPTARG' for option 'g'"
            printf '%s\n' "Try 'backup -h' for more information."
            exit 1
            ;;
        esac
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

shift $((OPTIND-1))
args=("$@")

# do not permit extra arguments
if [ "$args" ]; then
    for c in "${args[@]}"; do
         err "Invalid argument '$c'"
    done

    printf '%s\n' "Try 'backup -h' for more information."
    exit 1
fi

# Determine whether or not to use graphical output
case "$graphical_override" in
1)
    graphical=1
    ;;
0)
    ;;
*)
    [ "$UTILITY_GRAPHICAL" = 1 ] && graphical=1
    ;;
esac

#
# Collect data
#

if [ -z "$target" ]; then
    if [ "$BACKUP_TARGET" ]; then
        target="$(realpath "$BACKUP_TARGET")"
    # use latest mounted real filesystem
    elif [ -e "$(df --output=source | tail -n 1)" ]; then
        target="$(realpath "$(df --output=source | tail -n 1)")"
    else
        err "Could not determine a suitable target"
        printf '%s\n' "Try 'backup -h' for more information."
        exit 1
    fi
fi

if [ -e "$target" ]; then
    target_source="$(df --output=source "$target" | tail -n 1)"
fi

if [ "$target_source" ]; then
    target_target="$(df --output=target "$target" | tail -n 1)"
    target_model="$(lsblk -no MODEL /dev/"$(lsblk -no PKNAME "$target_source")")"
fi

#n_inode=$(df --output=iused / | tail -n 1)

#
# Run checks
#

if [ -z $skip_check ]; then
    check_exclude ()
    {
        # succeed if target is in excluded dirs
        # get first element in path (ugly)
        case "$(sed 's/\/[^/]*//2g' <<< "$target")" in
        /dev|/proc|/sys|/tmp|/run|/mnt)
            return
            ;;
        esac

        return 1
    }

    check_root ()
    {
        # succeed if root
        [ "$target_target" = "/" ]
    }

    check_space ()
    {
        # succeed if not enough space
        [ $(df --output=used -k / | tail -n 1) \
        -gt $(df --output=size -k "$target" | tail -n 1) ]
    }

    # a recursive backup would be extremely dangerous for the filesystem
    if ! check_exclude; then
        err "Recursive backups are not permitted"
        printf '%s\n' "The target may be mounted to a non-standard location."
        recursive_backup=1
    fi

    if [ $(id -u) != 0 ]; then
        warn "We do not have root privileges"
    fi

    if [ -d "$target" -a "$target_model" ]; then
        if [ -w "$target" ]; then
            if check_root; then
                warn "Target drive '$target_model' is the root drive"
                target_is_root=1
            fi

            if check_space; then
                warn "Target drive '$target_model' has insufficient free space"
            fi
        else
            warn "Target '$target' is inaccessible"
        fi
    elif [ -e "$target" ]; then
        warn "Target '$target' is invalid"
    else
        warn "Target '$target' does not exist"
    fi
fi

#
# Confirm or announce target
#

if [ $skip_interact ]; then
    if [ "$target_model" ]; then
        info "Target is '$target' on '$target_model'"
    else
        info "Target is '$target'"
    fi
else
    if [ $recursive_backup ]; then
        if ask "Exclude '$target' from backup?"; then
            rsync_exclude+="$target"
        else
            exit
        fi
    fi

    if [ "$target_model" ]; then
        ask "Backup to '$target' on '$target_model'?" \
            || exit 0
    else
        ask "Backup to '$target'?" \
            || exit 0
    fi
fi

#
# Run the backup
#

if [ "$verbose" -o "$log" ]; then
    # verbose
    rsync_opt="-v"
else
    # progress indicator
    rsync_opt="--info=progress2"
fi

back ()
{
    # default exclusions should be proper for most cases
    rsync -aHAXE "$rsync_opt" --delete / \
    --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/lost+found","/swapfile","$rsync_exclude"} \
    "$target"
}

clean ()
{
    if [ -z "$skip_interact" -a -z "$target_is_root" -a "$target_model" ]; then
        ask "Unmount target drive '$target_model' at '$target_target'?" \
            && umount "$target_target"
    fi
}

gclean ()
{
    if [ -z "$skip_interact" -a -z "$target_is_root" -a "$target_model" ]; then
        gask "Unmount target drive '$target_model' at '$target_target'?" \
            && umount "$target_target"
    fi
}

if [ "$log" ]; then
    log_file="$(realpath backup.log)"

    if [ -w . ]; then
        back &> "$log_file" &
        rsync_pid=$!
        info "Log file is '$log_file'"

        # very approximative and unreliable
        file_count ()
        {
            wc -l < $log_file
        }
    else
        back &> /dev/null &
        rsync_pid=$!
        err "Could not create log file"

        file_count ()
        {
            printf '?'
        }
    fi

    while kill -0 $rsync_pid 2> /dev/null; do
        for c in '   ' '.  ' '.. ' '...'; do
            printf '%b%binfo:%b %s %s'      \
            "$clear_line"                   \
            "$bold_blue"                    \
            "$normal"                       \
            "Backup in progress$c"          \
            "($(file_count) files copied)"
            sleep 0.5
        done
    done

    printf '\n'

    if [ $graphical ]; then
        if wait $rsync_pid; then
            ginfo "Backup successful"; gclean
            exit
        else
            gerr "Backup failed"
            [ -e $log_file ] \
                && ginfo "See '$log_file' for more information."
            exit 2
        fi
    else
        if wait $rsync_pid; then
            info "Backup successful"; clean
            exit
        else
            err "Backup failed"
            [ -e $log_file ] \
                && printf '%s\n' "See '$log_file' for more information."
            exit 2
        fi
    fi
else
    if [ $graphical ]; then
        if back; then
            ginfo "Backup successful" && gclean
            exit
        else
            gerr "Backup failed"
            exit 2
        fi
    elif ! backup; then
        exit 2
    fi
fi
