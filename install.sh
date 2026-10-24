#!/usr/bin/env bash
# NixOS from the minimal ISO: UEFI, GPT, LUKS2, Btrfs (zstd), zram, flakes.
#
# Run as root on the live ISO, from a complete repository checkout (it is copied, with .git, to ~/nixos):
#
#   sudo ./install.sh mango  /dev/nvme0n1     # MangoWM + Noctalia
#   sudo ./install.sh plasma /dev/nvme0n1     # KDE Plasma 6 + SDDM
#
# This WIPES the whole disk. You are asked once for a password. It is used for
# the LUKS passphrase and the login of user "m" (root login is disabled).
# Keep the two identical: the keyring and the lock screen use the same password.
#
# Non-interactive (ends up in your shell history, avoid): PW='...' YES=1 sudo -E ./install.sh ...
set -euo pipefail
exec > >(tee -a /tmp/install.log) 2>&1 # keep a log of the install run

PROFILE="${1:-}"
DISK="${2:-}"
PW="${PW:-}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG=/mnt/etc/nixos # temporary location during the install, moved to ~/nixos at the end
TMP_SWAP=/mnt/.installer-swap
Z=""

die() { echo "ERROR: $*" >&2; exit 1; }
step() { echo; echo "==> $*"; }

# Remove the temporary swap file and zram again, whatever happens.
cleanup() {
  if [[ -e $TMP_SWAP ]]; then
    swapoff "$TMP_SWAP" 2>/dev/null || true
    rm -f "$TMP_SWAP"
  fi
  if [[ -n "${Z:-}" && -b "${Z:-}" ]]; then
    swapoff "$Z" 2>/dev/null || true
    zramctl -r "$Z" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# ---------- preflight (nothing is touched yet) ----------
[[ $PROFILE == mango || $PROFILE == plasma ]] || die "usage: $0 <mango|plasma> <disk>   e.g. $0 mango /dev/nvme0n1"
[[ $EUID -eq 0 ]] || die "run as root (sudo -i first)"
[[ -n $DISK && -b $DISK ]] || die "usage: $0 <mango|plasma> <disk>   e.g. $0 mango /dev/nvme0n1"
[[ -d /sys/firmware/efi ]] || die "not booted in UEFI mode"
for f in flake.nix flake.lock common/base.nix common/vars.nix "nixos-$PROFILE/configuration.nix" "nixos-$PROFILE/home.nix"; do
  [[ -f $REPO_ROOT/$f ]] || die "missing $REPO_ROOT/$f"
done
for d in dotfiles flakes; do
  [[ -d $REPO_ROOT/$d ]] || die "missing $REPO_ROOT/$d (referenced by the flake, the build would fail)"
done
# Host and user come from common/vars.nix, the single source for all modules.
vars_get() { nix-instantiate --eval -E "(import (/. + \"$REPO_ROOT/common/vars.nix\")).$1" | tr -d '"'; }
HOST=$(vars_get host)
USER_NAME=$(vars_get user)
# Refuse a disk with mounted partitions (that is usually the installer USB stick).
if lsblk -nro MOUNTPOINTS "$DISK" | grep -q .; then
  die "$DISK has mounted partitions (is it the installer USB stick?). Unmount them or pick another disk."
fi
curl --fail --silent --show-error --head --connect-timeout 5 --max-time 10 \
  https://cache.nixos.org/nix-cache-info >/dev/null \
  || die "cannot reach the Nix cache over HTTPS (connect with nmtui first)"

lsblk "$DISK"
if [[ ${YES:-0} != 1 ]]; then
  read -rp "Wipe ALL of $DISK and install '$HOST' ($PROFILE)? Type YES: " ans
  [[ $ans == YES ]] || die "aborted"
fi

# ---------- password ----------
if [[ -z $PW ]]; then
  while :; do
    read -rsp "Password for LUKS and user '$USER_NAME': " PW; echo
    [[ -n $PW ]] || { echo "must not be empty"; continue; }
    read -rsp "Repeat: " PW2; echo
    [[ $PW == "$PW2" ]] && break
    echo "does not match, try again"
  done
  unset PW2
fi
[[ -n $PW ]] || die "empty password"
[[ $PW != *$'\n'* ]] || die "password must not contain a newline"

# ---------- clean state from a previous attempt ----------
step "Cleaning up previous mounts"
swapoff -a 2>/dev/null || true
umount -R /mnt 2>/dev/null || true
cryptsetup close cryptroot 2>/dev/null || true

# ---------- nix settings for the installer ----------
step "Enabling flakes"
mkdir -p ~/.config/nix
{
  echo "experimental-features = nix-command flakes"
  if [[ $PROFILE == mango ]]; then
    echo "extra-substituters = https://noctalia.cachix.org"
    echo "extra-trusted-public-keys = noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
  fi
} > ~/.config/nix/nix.conf
unset NIX_CONFIG
nix config show | grep -q flakes || die "flakes not enabled in nix config"

# ---------- partition, encrypt, format ----------
step "Partitioning $DISK"
wipefs -af "$DISK"
parted -s "$DISK" -- mklabel gpt
parted -s "$DISK" -- mkpart ESP fat32 1MiB 1GiB
parted -s "$DISK" -- set 1 esp on
parted -s "$DISK" -- mkpart nixos 1GiB 100%
udevadm settle
sleep 1

if [[ "$DISK" =~ [0-9]$ ]]; then
  P_ESP="${DISK}p1"
  P_ROOT="${DISK}p2"
else
  P_ESP="${DISK}1"
  P_ROOT="${DISK}2"
fi

step "Formatting and encrypting"
mkfs.fat -F 32 -n BOOT "$P_ESP"
printf '%s' "$PW" | cryptsetup luksFormat --type luks2 --batch-mode --key-file=- "$P_ROOT"
printf '%s' "$PW" | cryptsetup open --key-file=- "$P_ROOT" cryptroot
mkfs.btrfs -f -L nixos /dev/mapper/cryptroot

step "Btrfs subvolumes and mounts"
M=/dev/mapper/cryptroot
mount "$M" /mnt
for s in @ @home @nix @log; do btrfs subvolume create "/mnt/$s"; done
umount /mnt

O=compress=zstd,noatime
mount -o "$O,subvol=@" "$M" /mnt
mkdir -p /mnt/{boot,home,nix,var/log}
mount -o "$O,subvol=@home" "$M" /mnt/home
mount -o "$O,subvol=@nix"  "$M" /mnt/nix
mount -o "$O,subvol=@log"  "$M" /mnt/var/log
mount -o umask=0077 /dev/disk/by-label/BOOT /mnt/boot
findmnt -R /mnt

# The live ISO keeps its build directories in RAM; a local compile can freeze
# the machine. Temporary swap (deleted at the end, the installed system uses zram only).
step "Temporary swap (8 GB file + zram) for the install"
btrfs filesystem mkswapfile --size 8g "$TMP_SWAP"
swapon "$TMP_SWAP"
modprobe zram
Z=$(zramctl -f -s 4G -a zstd)
mkswap "$Z"
swapon -p 100 "$Z"
swapon --show

# ---------- config ----------
step "Generating hardware config and installing the flake"
nixos-generate-config --root /mnt
GEN_SV=$(sed -n 's/.*system\.stateVersion = "\([^"]*\)".*/\1/p' "$CFG/configuration.nix" | head -1)
grep -q cryptroot "$CFG/hardware-configuration.nix" \
  || die "hardware-configuration.nix has no luks device 'cryptroot'"

# nixos-generate-config records the temporary swap file as a swap device; the
# installed system uses zram only, so drop it again.
sed -i -z 's/swapDevices = \[[^]]*\];/swapDevices = [ ];/' "$CFG/hardware-configuration.nix"

HW_TMP=$(mktemp)
mv "$CFG/hardware-configuration.nix" "$HW_TMP"
rm -f -- "$CFG/configuration.nix"

# Copy the complete checkout (including .git, README, docs, wallpapers, ...) so
# ~/nixos is a working clone and nothing needs to be kept in sync by hand.
cp -a --no-preserve=ownership "$REPO_ROOT/." "$CFG/"
printf '%s\n' "$PROFILE" > "$CFG/profile"
# Only the chosen variant gets the generated hardware config; a foreign one from
# the repo must not stay behind.
rm -f -- "$CFG/nixos-mango/hardware-configuration.nix" "$CFG/nixos-plasma/hardware-configuration.nix"
mv "$HW_TMP" "$CFG/nixos-$PROFILE/hardware-configuration.nix"

if ! grep -q "stateVersion = \"$GEN_SV\"" "$CFG/nixos-$PROFILE/configuration.nix"; then
  echo "WARNING: generated stateVersion is $GEN_SV but nixos-$PROFILE/configuration.nix sets something else." >&2
  echo "         (home.nix has its own home.stateVersion.) Edit it if you want them equal." >&2
fi

cd "$CFG"
[[ -d .git ]] || git init -q # a zip download has no history
git add -A # flakes ignore untracked files
git -c user.name="Installer" -c user.email="installer@localhost" commit -q -m "Installation: $PROFILE profile and generated hardware configuration"

# ---------- install ----------
step "nixos-install (this takes a while)"
swapon --show
MAX_JOBS="${MAX_JOBS:-1}"
nixos-install --flake "$CFG#nixbox-$PROFILE" --no-root-passwd --max-jobs "$MAX_JOBS"

step "Setting password for $USER_NAME (root login is disabled in the config)"
printf '%s\n' "$USER_NAME:$PW" | nixos-enter --root /mnt -c chpasswd

# ---------- move the config to ~/nixos (programs.nh.flake points there) ----------
step "Moving the configuration to /home/$USER_NAME/nixos"
nixos-enter --root /mnt -c "mkdir -p /home/$USER_NAME && chown $USER_NAME:users /home/$USER_NAME"
cp -a "$CFG" "/mnt/home/$USER_NAME/nixos"
nixos-enter --root /mnt -c "chown -R $USER_NAME:users /home/$USER_NAME/nixos"
find "$CFG" -mindepth 1 -delete

cleanup
cp /tmp/install.log /mnt/var/log/install.log 2>/dev/null || true
cd /
umount -R /mnt || echo "WARNING: could not unmount /mnt cleanly (reboot is fine)" >&2
cryptsetup close cryptroot || true

cat <<EOF

==> Done. Remove the USB stick and run: reboot

At boot you type the LUKS passphrase once; the desktop then starts without a
second login prompt (Mango). The password you entered is also the password of
$USER_NAME (root is locked; use sudo) and of the lock screen.
Your configuration is in ~/nixos. Rebuild with: nh os switch   (alias: rebuild)
EOF
