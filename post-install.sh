#!/usr/bin/env bash
# Post install: run as the normal user on the INSTALLED system (not on the ISO).
#
#   cd ~/nixos && ./post-install.sh
#
# install.sh (base stage) leaves a working system with a small package set. This
# script switches the configuration to the "full" stage (file ./stage) and applies
# it with nh: large applications, VeraCrypt, the local package flakes (hylki, bibox,
# mtplayer, ...) and the Mango extras. It can be repeated; if the build fails,
# ./stage is set back and the running system stays as it was.
#
# Extra arguments are passed to nh, e.g.:  ./post-install.sh -- --max-jobs 2
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAGE_FILE="$REPO_ROOT/stage"

die() { echo "ERROR: $*" >&2; exit 1; }
step() { echo; echo "==> $*"; }

# ---------- preflight ----------
[[ $EUID -ne 0 ]] || die "run as your normal user, not root (nh asks for sudo itself)"
[[ -f /etc/NIXOS ]] || die "this is not a NixOS system; the post install runs on the installed system, not on the ISO"
command -v nh >/dev/null || die "nh not found (is this the installed system?)"
[[ -f $REPO_ROOT/flake.nix && -f $REPO_ROOT/common/post-install.nix ]] || die "$REPO_ROOT is not a complete checkout"
[[ -f $REPO_ROOT/profile ]] || die "missing $REPO_ROOT/profile (written by install.sh)"
curl --fail --silent --show-error --head --connect-timeout 5 --max-time 10 \
  https://cache.nixos.org/nix-cache-info >/dev/null \
  || die "cannot reach the Nix cache over HTTPS (connect with nmtui or the desktop first)"

OLD_STAGE=$(tr -d '[:space:]' < "$STAGE_FILE" 2>/dev/null || true)
OLD_STAGE="${OLD_STAGE:-full}"
DONE=0
restore() {
  if [[ $DONE -ne 1 ]]; then
    printf '%s\n' "$OLD_STAGE" > "$STAGE_FILE"
    git -C "$REPO_ROOT" add stage 2>/dev/null || true
    echo "Post install did not finish: ./stage is back to '$OLD_STAGE'. Fix the error and run ./post-install.sh again." >&2
  fi
}
trap restore EXIT

# ---------- switch to the full stage ----------
step "Switching ./stage to 'full' (was '$OLD_STAGE')"
printf 'full\n' > "$STAGE_FILE"
git -C "$REPO_ROOT" add stage # flakes ignore untracked files

step "Building and activating the full configuration (this takes a while)"
cd "$REPO_ROOT"
nh os switch "$@"
DONE=1

# ---------- record it ----------
if git -C "$REPO_ROOT" diff --cached --quiet -- stage; then
  echo "stage already committed as 'full'"
else
  git -C "$REPO_ROOT" commit -q -m "Post install: stage full" -- stage || echo "NOTE: could not commit ./stage; commit it yourself." >&2
fi

cat <<'DONE_MSG'

==> Post install finished. The full application set is installed.
Reload the session (Mango: SUPER + r, or log out and in) so new desktop entries show up.
From now on update with: nh os switch   (alias: rebuild)
DONE_MSG
