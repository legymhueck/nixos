#!/usr/bin/env bash
# Optional cached-app install: run as the normal user on the INSTALLED system.
#
#   cd ~/nixos && ./install-heavy-apps.sh
#
# This adds the large nixpkgs applications by switching ./stage to "apps".
# Run ./install-built-packages.sh afterwards for local flakes and unfree apps.
#
# Extra arguments are passed to nh, e.g.:  ./install-heavy-apps.sh -- --max-jobs 2
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAGE_FILE="$REPO_ROOT/stage"

die() { echo "ERROR: $*" >&2; exit 1; }
step() { echo; echo "==> $*"; }

# ---------- preflight ----------
[[ $EUID -ne 0 ]] || die "run as your normal user, not root (nh asks for sudo itself)"
[[ -f /etc/NIXOS ]] || die "this is not a NixOS system; the heavy-app install runs on the installed system, not on the ISO"
command -v nh >/dev/null || die "nh not found (is this the installed system?)"
[[ -f $REPO_ROOT/flake.nix && -f $REPO_ROOT/common/post-install.nix ]] || die "$REPO_ROOT is not a complete checkout"
[[ -f $REPO_ROOT/profile ]] || die "missing $REPO_ROOT/profile (written by install.sh)"
curl --fail --silent --show-error --head --connect-timeout 5 --max-time 10 \
  https://cache.nixos.org/nix-cache-info >/dev/null \
  || die "cannot reach the Nix cache over HTTPS (connect with nmtui or the desktop first)"

OLD_STAGE=$(tr -d '[:space:]' < "$STAGE_FILE" 2>/dev/null || true)
OLD_STAGE="${OLD_STAGE:-base}"
[[ $OLD_STAGE == base ]] || die "expected ./stage to be 'base', found '$OLD_STAGE'; apps are installed only once before built packages"
DONE=0
restore() {
  if [[ $DONE -ne 1 ]]; then
    printf '%s\n' "$OLD_STAGE" > "$STAGE_FILE"
    git -C "$REPO_ROOT" add stage 2>/dev/null || true
    echo "Heavy-app install did not finish: ./stage is back to '$OLD_STAGE'. Fix the error and run ./install-heavy-apps.sh again." >&2
  fi
}
trap restore EXIT

# ---------- switch to apps stage ----------
step "Switching ./stage to 'apps' (was '$OLD_STAGE')"
printf 'apps\n' > "$STAGE_FILE"
git -C "$REPO_ROOT" add stage # flakes ignore untracked files

step "Building and activating the large application set (this takes a while)"
cd "$REPO_ROOT"
nh os switch "$@"
DONE=1

# ---------- record it ----------
if git -C "$REPO_ROOT" diff --cached --quiet -- stage; then
  echo "stage already committed as 'apps'"
else
  git -C "$REPO_ROOT" commit -q -m "Install cached apps: stage apps" -- stage || echo "NOTE: could not commit ./stage; commit it yourself." >&2
fi

cat <<'DONE_MSG'

==> Cached large applications installed.
Next run ./install-built-packages.sh for local flakes and unfree applications.
DONE_MSG
