#!/usr/bin/env bash
# Set the standard permissions on ~/.ssh: 700 for directories, 600 for files,
# 644 for public keys and known_hosts*.
set -euo pipefail

dir="${1:-$HOME/.ssh}"
[[ -d $dir ]] || { echo "No such directory: $dir" >&2; exit 1; }

chmod 700 "$dir"
find "$dir" -mindepth 1 -type d -exec chmod 700 {} +
find "$dir" -type f -exec chmod 600 {} +
find "$dir" -type f -name '*.pub' -exec chmod 644 {} +
find "$dir" -maxdepth 1 -type f -name 'known_hosts*' -exec chmod 644 {} +
echo "Permissions fixed in $dir"
