#!/usr/bin/env bash
# Show which flake inputs have newer upstream commits, without changing
# anything. See docs/tips/commands.md ("Is an update worth it?").
set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") [REPO]

Compare every input in REPO/flake.lock (default ~/nixos) with its upstream
branch and show which ones have newer commits. Read-only: nothing is changed.
EOF
}

case "${1:-}" in
    -h|--help) usage; exit 0 ;;
esac

repo="${1:-$HOME/nixos}"
lock="$repo/flake.lock"
[[ -f $lock ]] || { echo "Error: $lock not found" >&2; exit 1; }

day() { date -u -d "@$1" +%F; }

# Upstream commit date via the GitHub API (rate-limited: "?" when it fails).
commit_day() {
    curl -sf --max-time 10 "https://api.github.com/repos/$1/$2/commits/$3" \
        | jq -r '.commit.committer.date[0:10]' 2>/dev/null || echo "?"
}

newer=0
nixpkgs_newer=false
printf '%-28s %-11s %s\n' INPUT LOCKED STATUS
while IFS=$'\t' read -r name type owner repo_name ref pin rev modified; do
    locked=$(day "$modified")
    if [[ $type != github ]]; then
        printf '%-28s %-11s %s\n' "$name" "$locked" "not checked ($type)"
        continue
    fi
    if [[ $pin != - ]]; then
        printf '%-28s %-11s %s\n' "$name" "$locked" "pinned to a commit"
        continue
    fi
    if ! upstream=$(git ls-remote "https://github.com/$owner/$repo_name" "$ref" | head -n 1 | cut -f1) \
        || [[ -z $upstream ]]; then
        printf '%-28s %-11s %s\n' "$name" "$locked" "could not reach GitHub"
        continue
    fi
    if [[ $upstream == "$rev" ]]; then
        printf '%-28s %-11s %s\n' "$name" "$locked" "up to date"
    else
        newer=$((newer + 1))
        [[ $name != nixpkgs ]] || nixpkgs_newer=true
        printf '%-28s %-11s %s\n' "$name" "$locked" \
            "NEWER upstream ($ref, $(commit_day "$owner" "$repo_name" "$upstream"))"
    fi
done < <(jq -r '
    .nodes as $nodes
    | .nodes.root.inputs | to_entries[]
    | $nodes[.value] as $n
    | [ .key, $n.locked.type, ($n.original.owner // "-"), ($n.original.repo // "-"),
        ($n.original.ref // "HEAD"), ($n.original.rev // "-"), ($n.locked.rev // "-"),
        ($n.locked.lastModified | tostring) ]
    | @tsv' "$lock")

echo
if (( newer == 0 )); then
    echo "Nothing new upstream: an update would change nothing."
else
    if [[ $nixpkgs_newer == true ]]; then
        echo "nixpkgs has moved: new package versions and fixes are available."
    else
        echo "nixpkgs has not moved: an update only brings the other inputs above."
    fi
    cat <<EOF
To see exactly what would change (builds, lists changed packages, does not switch):
  cd $repo && nh os build --update
Then apply it with 'rebuild' and commit flake.lock, or discard it with:
  git -C $repo checkout flake.lock
EOF
fi
