#!/usr/bin/env bash
# Shrink images by re-encoding them as WebP. Run with --help for usage;
# a cheat sheet with examples is in docs/tips/commands.md.
set -euo pipefail

QUALITY=85

usage() {
    cat <<EOF
Usage: $(basename "$0") [-q QUALITY] FILE...

Convert images (JPG, PNG, AVIF, ...) into WebP, written next to each
input. Existing files are never overwritten, inputs that are already
WebP are skipped. On photos and wallpapers this typically saves 80-90%,
and the images remain sharp enough - quality 85 is hard to tell apart
from the original.

  -q QUALITY  0-100. Higher = better and larger. Default: 85.

Examples:
  $(basename "$0") wallpaper.png
  $(basename "$0") *.jpg *png

More commands: ~/nixos/docs/tips/commands.md
EOF
}

while (( $# > 0 )); do
    case "$1" in
        -q) [[ $# -ge 2 ]] || { echo "Error: -q needs a value." >&2; exit 1; }; QUALITY="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        --) shift; break ;;
        -*) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
        *) break ;;
    esac
done
(( $# > 0 )) || { usage >&2; exit 1; }

for in in "$@"; do
    [[ -f $in ]] || { echo "Skipping $in: not a file" >&2; continue; }
    [[ ${in##*.} != webp ]] || { echo "Skipping $in: already WebP" >&2; continue; }
    out="${in%.*}.webp"
    if [[ -e $out ]]; then
        echo "Skipping $in: $out already exists" >&2
        continue
    fi

    echo "==> $in -> $out"
    magick "$in" -quality "$QUALITY" -define webp:method=6 "$out"
    echo "    $(du -h "$in" | cut -f1) -> $(du -h "$out" | cut -f1)"
done
