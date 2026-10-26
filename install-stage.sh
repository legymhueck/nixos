#!/usr/bin/env bash
# Post-install steps: run as the normal user on the INSTALLED system, in order.
#
#   cd ~/nixos
#   ./install-stage.sh apps    # base -> apps: large applications from nixpkgs
#   ./install-stage.sh full    # apps -> full: local packages, customized builds, unfree apps
#
# Extra arguments are passed to nh, e.g.: ./install-stage.sh apps -- --max-jobs 2
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAGE_FILE="$REPO_ROOT/stage"

die() { echo "ERROR: $*" >&2; exit 1; }
step() { echo; echo "==> $*"; }

NEW_STAGE="${1:-}"
case $NEW_STAGE in
  apps) EXPECTED=base; WHAT="the large application set" ;;
  full) EXPECTED=apps; WHAT="local packages, customized builds and unfree applications" ;;
  *) die "usage: $0 <apps|full> [nh arguments]   (run 'apps' first, then 'full')" ;;
esac
shift

# ---------- preflight ----------
[[ $EUID -ne 0 ]] || die "run as your normal user, not root (nh asks for sudo itself)"
[[ -f /etc/NIXOS ]] || die "this is not a NixOS system; run this on the installed system, not on the ISO"
command -v nh >/dev/null || die "nh not found (is this the installed system?)"
[[ -f $REPO_ROOT/flake.nix && -f $REPO_ROOT/common/apps.nix && -f $REPO_ROOT/common/built.nix ]] \
  || die "$REPO_ROOT is not a complete checkout"
[[ -f $REPO_ROOT/profile ]] || die "missing $REPO_ROOT/profile (written by install.sh)"

OLD_STAGE=$(tr -d '[:space:]' < "$STAGE_FILE" 2>/dev/null || true)
OLD_STAGE="${OLD_STAGE:-base}"
[[ $OLD_STAGE == "$EXPECTED" ]] \
  || die "expected ./stage to be '$EXPECTED' before '$NEW_STAGE', found '$OLD_STAGE' (order: apps, then full)"
curl --fail --silent --show-error --head --connect-timeout 5 --max-time 10 \
  https://cache.nixos.org/nix-cache-info >/dev/null \
  || die "cannot reach the Nix cache over HTTPS (connect with nmtui or the desktop first)"

DONE=0
restore() {
  if [[ $DONE -ne 1 ]]; then
    printf '%s\n' "$OLD_STAGE" > "$STAGE_FILE"
    git -C "$REPO_ROOT" add stage 2>/dev/null || true
    echo "Install did not finish: ./stage is back to '$OLD_STAGE'. Fix the error and run $0 $NEW_STAGE again." >&2
  fi
}
trap restore EXIT

# ---------- switch ----------
step "Switching ./stage to '$NEW_STAGE' (was '$OLD_STAGE')"
printf '%s\n' "$NEW_STAGE" > "$STAGE_FILE"
git -C "$REPO_ROOT" add stage # flakes ignore untracked files

step "Building and activating $WHAT (this takes a while)"
cd "$REPO_ROOT"
nh os switch "$@"
DONE=1

# ---------- record it ----------
if git -C "$REPO_ROOT" diff --cached --quiet -- stage; then
  echo "stage already committed as '$NEW_STAGE'"
else
  git -C "$REPO_ROOT" commit -q -m "Install stage $NEW_STAGE" -- stage \
    || echo "NOTE: could not commit ./stage; commit it yourself." >&2
fi

echo
if [[ $NEW_STAGE == apps ]]; then
  echo "==> Large applications installed. Next: ./install-stage.sh full"
else
  cat <<'DONE_MSG'
==> Local packages and unfree applications installed. The full configuration is active.
Reload the session (Mango: SUPER + r, or log out and in) so new desktop entries show up.
From now on update with: nh os switch   (alias: rebuild)
DONE_MSG
fi
