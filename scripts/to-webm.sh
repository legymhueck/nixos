#!/usr/bin/env bash
# Shrink recordings into browser-playable videos. Run with --help for usage;
# a cheat sheet with examples is in docs/tips/commands.md.
set -euo pipefail

FORMAT=webm
QUALITY=""

usage() {
    cat <<EOF
Usage: $(basename "$0") [--mp4] [-q QUALITY] FILE...

Re-encode (screen) recordings into small videos that browsers play. The result
is written next to each input; existing files are never overwritten. Videos
wider than 1920 px are scaled down to 1920 px.

  (default)   WebM, AV1 + Opus: smallest. Chrome, Edge, Firefox; Safari only
              on devices with AV1 hardware (iPhone 15 Pro, M3 Macs and newer).
  --mp4       MP4, H.264 + AAC: larger, but plays everywhere (older iPads too).
  -q QUALITY  Lower = better and larger. Default 35 (AV1, 0-63) or 28 (H.264, 0-51).

Examples:
  $(basename "$0") Recording.mp4
  $(basename "$0") --mp4 *.mp4

More commands: ~/nixos/docs/tips/commands.md
EOF
}

while (( $# > 0 )); do
    case "$1" in
        --mp4) FORMAT=mp4; shift ;;
        -q) [[ $# -ge 2 ]] || { echo "Error: -q needs a value." >&2; exit 1; }; QUALITY="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        --) shift; break ;;
        -*) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
        *) break ;;
    esac
done
(( $# > 0 )) || { usage >&2; exit 1; }

if [[ $FORMAT == webm ]]; then
    export SVT_LOG=1 # SVT-AV1: errors only, no banner
    codec=(-c:v libsvtav1 -preset 8 -crf "${QUALITY:-35}" -c:a libopus -b:a 64k -cues_to_front 1)
else
    codec=(-c:v libx264 -preset slow -crf "${QUALITY:-28}" -c:a aac -b:a 96k -movflags +faststart)
fi

for in in "$@"; do
    [[ -f $in ]] || { echo "Skipping $in: not a file" >&2; continue; }
    out="${in%.*}.$FORMAT"
    [[ $out != "$in" ]] || out="${in%.*}-small.$FORMAT"
    if [[ -e $out ]]; then
        echo "Skipping $in: $out already exists" >&2
        continue
    fi

    echo "==> $in -> $out"
    ffmpeg -hide_banner -loglevel error -stats -i "$in" \
        -map 0:v:0 -map '0:a?' \
        -vf "scale='min(1920,iw)':-2" -pix_fmt yuv420p \
        "${codec[@]}" "$out"
    echo "    $(du -h "$in" | cut -f1) -> $(du -h "$out" | cut -f1)"
done
