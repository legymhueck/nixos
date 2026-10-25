#!/usr/bin/env bash
# Install local flakes, customized builds, and optional unfree applications
# after the cached large application set has been installed.
#
#   cd ~/nixos && ./install-built-packages.sh
#
# Extra arguments are passed to nh, e.g.: ./install-built-packages.sh -- --max-jobs 2
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAGE_FILE="$REPO_ROOT/stage"

die() { echo "ERROR: $*" >&2; exit 1; }
step() { echo; echo "==> $*"; }

[[ $EUID -ne 0 ]] || die "run as your normal user, not root (nh asks for sudo itself)"
[[ -f /etc/NIXOS ]] || die "this is not a NixOS system; built packages install on the installed system, not on the ISO"
command -v nh >/dev/null || die "nh not found (is this the installed system?)"
[[ -f $REPO_ROOT/flake.nix && -f $REPO_ROOT/common/built-packages.nix ]] || die "$REPO_ROOT is not a complete checkout"
[[ -f $REPO_ROOT/profile ]] || die "missing $REPO_ROOT/profile (written by install.sh)"

OLD_STAGE=$(tr -d '[:space:]' < "$STAGE_FILE" 2>/dev/null || true)
[[ $OLD_STAGE == apps ]] || die "expected ./stage to be 'apps'; run ./install-heavy-apps.sh first (current stage: ${OLD_STAGE:-missing})"
curl --fail --silent --show-error --head --connect-timeout 5 --max-time 10 \
  https://cache.nixos.org/nix-cache-info >/dev/null \
  || die "cannot reach the Nix cache over HTTPS (connect with nmtui or the desktop first)"

DONE=0
restore() {
  if [[ $DONE -ne 1 ]]; then
    printf '%s\n' "$OLD_STAGE" > "$STAGE_FILE"
    git -C "$REPO_ROOT" add stage 2>/dev/null || true
    echo "Built-package install did not finish: ./stage is back to '$OLD_STAGE'. Fix the error and run ./install-built-packages.sh again." >&2
  fi
}
trap restore EXIT

step "Switching ./stage to 'full' (was '$OLD_STAGE')"
printf 'full\n' > "$STAGE_FILE"
git -C "$REPO_ROOT" add stage

step "Building and activating local flakes and unfree applications"
cd "$REPO_ROOT"
nh os switch "$@"
DONE=1

if git -C "$REPO_ROOT" diff --cached --quiet -- stage; then
  echo "stage already committed as 'full'"
else
  git -C "$REPO_ROOT" commit -q -m "Built packages: stage full" -- stage || echo "NOTE: could not commit ./stage; commit it yourself." >&2
fi

cat <<'DONE_MSG'

==> Local flakes and unfree applications installed. The full configuration is active.
Reload the session (Mango: SUPER + r, or log out and in) so new desktop entries show up.
From now on update with: nh os switch   (alias: rebuild)
DONE_MSG
