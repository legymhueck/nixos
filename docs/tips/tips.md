# Tips

## Manual install instead of `install.sh`

Follow `docs/install_guide/nixos-install-guide.typ`. After `nixos-generate-config --root /mnt`, copy the whole repository layout (the flake refers to all of it) and move the generated hardware module into the variant directory:

```sh
scp -r flake.nix flake.lock profile common nixos-mango nixos-plasma dotfiles flakes \
  root@<iso-ip>:/mnt/etc/nixos/
# on the ISO:
mv /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/nixos-mango/
rm /mnt/etc/nixos/configuration.nix
rm -f /mnt/etc/nixos/nixos-plasma/hardware-configuration.nix
echo mango > /mnt/etc/nixos/profile      # or plasma
```

## Change the password for m (root login is disabled)

```sh
nixos-enter --root /mnt -c "printf '%s\n' 'm:PASSWORD' | chpasswd"
```

On an installed system use `passwd` and also change the LUKS passphrase to the same string (see README).
