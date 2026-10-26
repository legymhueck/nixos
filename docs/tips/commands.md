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

## System

```sh
rebuild                        # nh os switch: apply the configuration
update                         # nh os switch --update: update inputs, then apply
nh os test                     # try a configuration without a boot entry
nh clean all --keep 5          # remove old generations now (also runs weekly)
nix flake check                # lint and evaluate (in ~/nixos)
```

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
