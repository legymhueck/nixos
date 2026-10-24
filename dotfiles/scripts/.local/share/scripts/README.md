# Scripts directory

Home Manager links the `*.sh` files into `~/.local/share/scripts` (executable).
Apply changes with `nh os switch` (alias `rebuild`).

| Script | Purpose |
| --- | --- |
| `delete_snapper_snapshots.sh` | Delete snapper snapshots interactively |
| `format-and-mount.sh` | Format and mount an encrypted LUKS + Btrfs partition |
| `nfs-mount.sh` | Mount NAS NFS shares |
| `ssh-permissions.sh` | Reset permissions in `~/.ssh` (700/600/644) |

## Shell Aliases and Functions

Shell shortcuts defined in `common/home.nix` (aliases without the `.sh` suffix, and functions):

- `create-ssh-key`: Alias for `ssh-keygen -t ed25519`
- `umount-drive`: Function that unmounts `~/mount` and closes the `micleh` LUKS mapper
- `ssh-permissions`: Shortcut to run `ssh-permissions.sh`
- `nfs-mount`: Shortcut to run `nfs-mount.sh`
- `snapper-delete`: Shortcut to run `delete_snapper_snapshots.sh`

Scripts that NixOS handles declaratively (groups, battery thresholds, CUPS, libvirt),
obsolete USB ramdisk scripts (`firefox-usb.sh`, `vscode-usb.sh`), and Arch-era helpers
(pacman cleanup, mkinitcpio/TPM2/FIDO2/YubiKey LUKS enrollment) were removed. Use `nh clean`
instead of a cleanup script.
