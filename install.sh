#!/usr/bin/env bash
#
# install.sh: Install utility scripts
#
# You can change the installation target by modifying the 'target' variable.
#
# Copyright (c) 2021 Emil Overbeck <https://github.com/Swarthe>
#
# Subject to the MIT License. See LICENSE.txt for more information.
#

#
# Collect data
#

bin_target="/usr/local/bin"
desktop_target="/usr/share/applications"
system="$(uname)"
target_files="$(basename -s .sh src/*; basename -a data/*)"
replaced_files=0

# Count the number of files to be replaced
while read -r f; do
    [ -e "${bin_target}/$f" -o -e "${desktop_target}/$f" ] \
        && replaced_files=$(($replaced_files + 1))
done <<< "$target_files"

#
# Run checks
#

if [ $(id -u) != 0 ]; then
    printf 'error: %s\n' "We do not have root privileges"
    printf '%s\n' "Try running this script with 'sudo'"
    exit 1
fi

if ! [ -e src ]; then
    printf 'error: %s\n' "Necessary files not found"
    printf '%s\n' "Try running this script in the root of the project directory"
    exit 2
fi

case "$system" in
Linux)
    printf '%s\n' "Host system is Linux; full compatibility"
    ;;
Darwin)
    printf '%s\n' "Host system is Darwin/MacOS; partial compatibility"
    ;;
*)
    printf '%s\n' "Host system is $system; unknown compatibility"
    ;;
esac

printf '\n'

#
# Run installation
#

printf '%s\n' "Target for executables is $bin_target"
printf '%s\n' "$(wc -l <<< $target_files) files to be installed"
printf '%s\n' "$replaced_files files to be replaced"
printf '\n'

install -v src/backup.sh        "${bin_target}/backup"  -o root -g root
install -v src/record.sh        "${bin_target}/record"  -o root -g root
install -v src/scot.sh          "${bin_target}/scot"    -o root -g root
install -v src/vimg.sh          "${bin_target}/vimg"    -o root -g root
install -v src/ydl.sh           "${bin_target}/ydl"     -o root -g root
install -v data/record.desktop  "$desktop_target"       -o root -g root
