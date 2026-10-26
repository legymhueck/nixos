# Tips

## Manual install instead of `install.sh`

Follow `docs/install_guide/nixos-install-guide.typ`. After `nixos-generate-config --root /mnt`, copy the whole repository layout (the flake refers to all of it) and move the generated hardware module into the variant directory:

```sh
scp -r flake.nix flake.lock profile stage common nixos-mango nixos-plasma dotfiles pkgs scripts \
  root@<iso-ip>:/mnt/etc/nixos/
# on the ISO:
mv /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/nixos-mango/
rm /mnt/etc/nixos/configuration.nix
rm -f /mnt/etc/nixos/nixos-plasma/hardware-configuration.nix
echo mango > /mnt/etc/nixos/profile      # or plasma
echo base  > /mnt/etc/nixos/stage        # or full; with base run ./install-stage.sh apps, then full, after the first boot
```

## Change the password for m (root login is disabled)

```sh
nixos-enter --root /mnt -c "printf '%s\n' 'm:PASSWORD' | chpasswd"
```

On an installed system use `passwd` and also change the LUKS passphrase to the same string (see README).

---

## Check if a font is installed

```bash
fc-match "JetBrains Mono NL"
fc-list | grep -i "JetBrains"
fc-list --format='%{family[0]}\n' | sort -u | grep -i jetbrains
fc-match "JetBrains Mono NL" --format='%{family}\n'
```
