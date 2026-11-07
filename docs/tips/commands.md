# Commands worth remembering

Every command below has `--help`. Own commands come from `scripts/` (see
`scripts/README.md`); aliases and functions are in `common/home.nix`.

## Shrink videos for students: `to-webm`

Screen recordings (Snipping Tool, OBS, ...) are huge; this makes them small and
browser-playable. The original stays, the result is written next to it.

```sh
to-webm Recording.mp4          # → Recording.webm (AV1): smallest
to-webm --mp4 Recording.mp4    # → Recording-small.mp4 (H.264): plays everywhere
to-webm *.mp4                  # all recordings in the folder
to-webm -q 40 Recording.mp4    # smaller, lower quality (default 35; --mp4: 28)
to-webm -q 28 Recording.mp4    # sharper text, larger file
```

- WebM plays in Chrome, Edge and Firefox (Windows, Chromebooks, Android).
- Use `--mp4` when students use iPads or older Macs.
- Wider than 1920 px is scaled down to 1920 px.

## Shrink images: `to-webp`

Convert pictures into WebP next to the originals; typically saves 80-90% on
wallpapers and photos (quality 85).

```sh
to-webp wallpaper.png      # → wallpaper.webp, the PNG stays
to-webp *.jpg              # all images in the folder
to-webp -q 95 photo.jpg    # for things you want to keep extra sharp
```

## Backup of the teaching archive: `restic-unterricht`

Encrypted, versioned backup of `~/Documents/GitHub/micleh/unterricht`
(including the git-ignored archive) with restic (`common/backup.nix`). The
target is a USB disk (ext4, label `restic-backup`) that lives outside the
house; restic encrypts everything itself, so no LUKS is needed. One-time setup:

```sh
lsblk -o NAME,SIZE,FSTYPE,LABEL,MODEL       # find the disk, e.g. /dev/sdc -- check twice
sudo wipefs -a /dev/sdc                     # erases the disk!
sudo parted -s /dev/sdc mklabel gpt mkpart restic 1MiB 100%
sudo mkfs.ext4 -L restic-backup /dev/sdc1
udisksctl mount -b /dev/sdc1                # -> /run/media/m/restic-backup
sudo install -d -o m -g users /run/media/m/restic-backup/restic
mkdir -p ~/.config/restic && chmod 700 ~/.config/restic
echo /run/media/m/restic-backup/restic/unterricht > ~/.config/restic/unterricht-repo
(umask 077; read -rs -p 'Passwort: ' pw; echo "$pw" > ~/.config/restic/unterricht-passwort)
restic-unterricht init                      # create the repository (once)
sudo systemctl start restic-backups-unterricht   # first backup (takes a while)
```

Keep the password in KeePassXC too: without it the backup cannot be read.
The daily timer only runs while the disk is attached; otherwise start it by
hand after plugging in. Unplug with `udisksctl unmount -b /dev/sdc1`.

```sh
restic-unterricht snapshots     # list backups
restic-unterricht ls latest | rg relative-clauses
restic-unterricht restore latest --target /tmp/wiederherstellen --include '*/englisch/grammatik'
restic-unterricht check         # verify the repository
systemctl list-timers restic-backups-unterricht
journalctl -u restic-backups-unterricht -e   # last run
```

## Full-text search: `recoll`

Indexes Word, LibreOffice, PDF, Markdown and text files in the teaching
repository (`services.recoll` in `common/apps.nix`), daily by a user timer.

```sh
systemctl --user start recollindex   # build the index now (first run: long)
recoll                               # search GUI: words, "phrases", ext:docx, dir:englisch
recollq 'Ayers Rock'                 # search in the terminal
```

## System

```sh
rebuild                        # nh os switch: apply the configuration
update                         # nh os switch --update: update inputs, then apply
nh os test                     # try a configuration without a boot entry
nh clean all --keep 5          # remove old generations now (also runs weekly)
nix flake check                # lint and evaluate (in ~/nixos)
```

### Is an update worth it?

```sh
update-check                   # which inputs have newer commits (changes nothing)
nh os build --update           # in ~/nixos: build the update, list changed packages, don't switch
rebuild                        # then apply it ...
git checkout flake.lock        # ... or throw the update away
```

`nixpkgs` is the input that matters: only when it has moved do you get new
package versions and fixes (it advances every few days, see
https://status.nixos.org, channel nixos-unstable). After an update that
works, commit the lock file: `git commit -am "flake.lock: update inputs"`
(see `commit-messages.md`).

## Drives and network

```sh
mnt /dev/sdb1                  # mount a USB partition (udisksctl)
format-and-mount               # WIPE a drive, set it up as LUKS + Btrfs, mount it
umount-drive                   # unmount ~/mount and close the "micleh" LUKS mapper
nfs-mount                      # mount the NAS shares (NFS_SERVER=... to change host)
partuuid                       # list partitions by PARTUUID
```

## Snapshots and Btrfs

```sh
snapper-delete --dry-run       # show which snapper snapshots would be deleted
snapper-delete                 # delete them (asks per config; -y for no questions)
bfree                          # Btrfs space usage
bscrub && bscrubStatus         # check the file system for errors
```

## SSH and keys

```sh
create-ssh-key                 # ssh-keygen -t ed25519
ssh-permissions                # fix permissions in ~/.ssh
fingerprint                    # enroll a fingerprint (fprintd)
```

## Printing

```sh
system-config-printer          # printer settings GUI (Mango; Plasma: System Settings > Printers)
lpstat -p -d                   # printers and the default one
lp file.pdf                    # print a file on the default printer (Kyocera FS-3820N, see docs/setup/printer.md)
lp -o sides=two-sided-long-edge file.pdf   # duplex (needs the duplex unit)
```

## Everyday helpers

```sh
ex archive.tar.gz              # extract almost any archive
l                              # eza -al --icons
bigFiles                       # sizes of everything below ., largest last
battery                        # battery details
sf                             # failed systemd units
journalInfo                    # errors of the current boot
programPath firefox            # where a command really lives in /nix/store
```
