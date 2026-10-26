# Scripts

`common/scripts.nix` installs each `<name>.sh` as the command `<name>`
(`writeShellApplication`: shellcheck at build time, dependencies on `PATH`).
To add one, put `<name>.sh` here, add a `mkScript` line with its runtime
dependencies, and list it in `docs/tips/commands.md` (usage examples for all
commands and aliases).

| Command | Purpose |
| --- | --- |
| `format-and-mount` | Format and mount an encrypted LUKS + Btrfs partition |
| `nfs-mount` | Mount NAS NFS shares |
| `snapper-delete` | Delete snapper snapshots interactively |
| `ssh-permissions` | Reset permissions in `~/.ssh` (700/600/644) |
| `to-webm` | Shrink recordings into browser-playable WebM (AV1) or, with `--mp4`, H.264 MP4 |
