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
# Collect/set information
#

target="/usr/local/bin"
system="$(uname)"
repo_files="$(basename -s .sh src/*)"
replaced_files=0

# Count the number of files to be replaced
while read -r f; do
    [ -e "${target}/$f" ] && replaced_files=$(($replaced_files + 1))
done <<< "$repo_files"

#
# Run checks
#

if [ $(id -u) != 0 ]; then
    printf 'error: %s\n' "We do not have root privileges"
    printf '%s\n' "Try running this script with 'sudo'"
    exit 1
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

printf '%s\n' "Target is $target"
printf '%s\n' "$(wc -l <<< $repo_files) files to be installed"
printf '%s\n' "$replaced_files files to be replaced"
printf '\n'

cp -v src/backup.sh    "${target}/backup"  && chown root:root "${target}/backup"
cp -v src/record.sh    "${target}/record"  && chown root:root "${target}/record"
cp -v src/scot.sh      "${target}/scot"    && chown root:root "${target}/scot"
cp -v src/vimg.sh      "${target}/vimg"    && chown root:root "${target}/vimg"
cp -v src/ydl.sh       "${target}/ydl"     && chown root:root "${target}/ydl"
printf '\n'

printf '%s\n' "Installation complete"
