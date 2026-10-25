// From the repository root: typst compile docs/install_guide/nixos-install-guide.typ --root .
#set document(title: "NixOS from the minimal ISO")
#set page(
  paper: "a4",
  margin: (x: 1.6cm, y: 1.6cm),
  numbering: "1 / 1",
  footer: context [
    #set text(fill: rgb("#666666"), size: 8pt)
    #grid(
      columns: (1fr, 1fr),
      align(left)[Created #datetime.today().display("[year]-[month]-[day]")],
      align(right)[Page #counter(page).display() of #counter(page).final().first()],
    )
  ],
)
#set text(font: "Carlito", size: 10pt, lang: "en")
#set par(justify: false, leading: 0.6em)
#set heading(numbering: "1.")
#show heading.where(level: 1): set text(size: 13pt)
#show heading.where(level: 1): set block(above: 1.3em, below: 0.7em)
#show raw: set text(font: ("DejaVu Sans Mono", "Liberation Mono"), size: 8pt)
#show raw.where(block: true): it => block(
  width: 100%, fill: luma(245), stroke: 0.5pt + luma(190),
  inset: 6pt, radius: 2pt, above: 0.6em, below: 0.8em, it,
)

#let note(body) = block(
  width: 100%, inset: 7pt, fill: rgb("#f1f5fa"),
  stroke: (left: 2pt + rgb("#3b6ea8")), above: 0.6em, below: 0.8em,
  [*Note.* #body],
)
#let warn(body) = block(
  width: 100%, inset: 7pt, fill: rgb("#fbf1f0"),
  stroke: (left: 2pt + rgb("#b3372d")), above: 0.6em, below: 0.8em,
  [*Careful.* #body],
)
#let file(name) = block(above: 0.8em, below: 0pt, sticky: true,
  text(font: "DejaVu Sans Mono", size: 8.5pt, weight: "bold", name))

#align(center)[
  #text(19pt, weight: "bold")[NixOS from the minimal ISO]
  #v(-2pt)
  #text(9.5pt)[UEFI · GPT · LUKS2 · Btrfs (zstd) · zram · flakes · Home Manager · MangoWM · Noctalia]
]
#v(4pt)

*Assumptions.* x86_64, UEFI, the whole disk gets wiped. Placeholders to replace:
disk `/dev/nvme0n1`, hostname `nixbox`, user `m`, time zone, keyboard layout.
The ISO is the current stable minimal ISO; the system tracks `nixos-unstable`
(rolling, like Arch). Everything lives in one git-tracked flake.
*Three stages:* the *base install* (from the ISO) builds the encrypted, bootable system with a small package set; two optional post-install steps add the large nixpkgs applications, then local flakes, customized builds, and optional unfree apps.
*One passphrase:* the LUKS passphrase is typed at boot, then the system logs in automatically and
unlocks the keyring with that same passphrase. Use *the same string* as login password for `m`.

= Optional: SSH into the live ISO

The NixOS installer ISO runs `sshd` by default, and its firewall opens SSH port 22 automatically. No separate enable or firewall command is normally needed. First connect the ISO to your network (wired Ethernet or `nmtui` for Wi-Fi), then on its console set a temporary root password and find its address:

```sh
sudo -i
passwd                       # set a temporary root password for this live session
ip -brief address            # note the ISO's LAN address
systemctl is-active sshd || systemctl start sshd  # start it only if it is not already active
```

From another computer on the same network, connect using that address:

```sh
ssh root@192.168.1.42        # replace with the address shown above
```

Accept the host key on first connection and enter the temporary root password. The password is only for the live ISO;
it does not set the installed system's password. In the SSH session, continue with the commands below and omit `sudo -i`.

= Boot the installer and get online

```sh
sudo -i                     # root shell (live ISO: no password)
loadkeys de-latin1          # optional: console keymap
ls /sys/firmware/efi        # must exist, otherwise you booted in BIOS mode
nmtui                       # Wi-Fi (wpa_cli if the ISO ships wpa_supplicant); wired just works
curl --fail --head --connect-timeout 5 https://cache.nixos.org/nix-cache-info
```

= Recommended: base install with the install script

The repository script `install.sh` replaces all the manual steps below, from partitioning through password setup. It wipes the selected disk, so use it *instead of* the manual steps, not after them. It needs a complete repository checkout and copies all of it, including `.git`, to `~/nixos`. It refuses a disk with mounted partitions, so it cannot wipe the installer stick by mistake.

On the live ISO (after `nmtui`), either clone the repository or copy it from another computer:

```sh
git clone https://github.com/legymhueck/nixos.git && cd nixos
# or, from another computer:  scp -r . root@<iso-ip>:/root/nixos
lsblk                                   # identify the target disk
./install.sh mango /dev/nvme0n1         # or: ./install.sh plasma /dev/nvme0n1
```

The script enables flakes (and the Noctalia binary cache for Mango, otherwise Noctalia is compiled locally), partitions, encrypts, formats, creates the subvolumes, installs, sets the password of `m` and moves the configuration to `~/nixos`. It installs the *base stage* (`stage` = `base`): the complete system, but only the small user package set from `common/home-packages.nix`. Large applications and local/unfree packages are intentionally separate follow-up steps after boot. It uses a temporary swap file only while installing and deletes it at the end. After reboot, continue with the post install below. The rest of this guide is the manual equivalent and a reference.

#note[The manual steps below show Mango. For Plasma replace `mango` with `plasma` and skip the Mango-only parts (Noctalia cache, keyring section).]

= Manual: enable flakes and the Noctalia cache

Use a config file; a multi-line `NIX_CONFIG` variable breaks if the line breaks get lost while copying.

```sh
mkdir -p ~/.config/nix
cat > ~/.config/nix/nix.conf <<'EOF'
experimental-features = nix-command flakes
extra-substituters = https://noctalia.cachix.org
extra-trusted-public-keys = noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=
EOF
nix config show | grep -E 'substituters|trusted-public|experimental'   # must list noctalia
```

= Partition, encrypt, format

```sh
DISK=/dev/nvme0n1                      # check with lsblk
wipefs -af $DISK
parted -s $DISK -- mklabel gpt
parted -s $DISK -- mkpart ESP fat32 1MiB 1GiB
parted -s $DISK -- set 1 esp on
parted -s $DISK -- mkpart nixos 1GiB 100%
udevadm settle

mkfs.fat -F 32 -n BOOT /dev/disk/by-partlabel/ESP
cryptsetup luksFormat /dev/disk/by-partlabel/nixos      # type YES, choose the passphrase
cryptsetup open /dev/disk/by-partlabel/nixos cryptroot  # name must stay "cryptroot"
mkfs.btrfs -L nixos /dev/mapper/cryptroot
```

#note[Only `/boot` (kernel, initrd) stays unencrypted; systemd-boot cannot unlock disks, the initrd asks for the passphrase.]

== Btrfs subvolumes and mounts

`@nix` is separate so root snapshots do not contain the store; `@log` survives a root rollback. There is no swap subvolume: the installed system uses zram only.

```sh
M=/dev/mapper/cryptroot
mount $M /mnt
for s in @ @home @nix @log; do btrfs subvolume create /mnt/$s; done
umount /mnt

O=compress=zstd,noatime
mount -o $O,subvol=@ $M /mnt
mkdir -p /mnt/{boot,home,nix,var/log}
mount -o $O,subvol=@home $M /mnt/home
mount -o $O,subvol=@nix  $M /mnt/nix
mount -o $O,subvol=@log  $M /mnt/var/log
mount -o umask=0077 /dev/disk/by-label/BOOT /mnt/boot
findmnt -R /mnt                         # sanity check
```

The live ISO keeps its store and build directories in RAM (`/nix/.rw-store` is a tmpfs), so a local compile can fill 8 GB of RAM and freeze the machine. Use a temporary swap file plus zram for the install only; delete the file afterwards (`swapoff /mnt/.installer-swap && rm /mnt/.installer-swap`):

```sh
btrfs filesystem mkswapfile --size 8g /mnt/.installer-swap
swapon /mnt/.installer-swap
modprobe zram
Z=$(zramctl -f -s 4G -a zstd) && mkswap "$Z" && swapon -p 100 "$Z"   # compressed RAM first, the file is overflow
swapon --show                           # swap file and zram must both be listed
free -h
```

= Generate the config and write the flake

```sh
nixos-generate-config --root /mnt
cd /mnt/etc/nixos
grep stateVersion configuration.nix     # remember this value, you need it below
```

`hardware-configuration.nix` is the only generated file you keep; check that it lists the four subvolumes, `/boot`
and `boot.initrd.luks.devices."cryptroot"`. Copy the root `flake.nix`, `flake.lock`, `profile`, `stage`, `common/`, `nixos-mango/`, `nixos-plasma/`, `dotfiles/` and `flakes/` into `/mnt/etc/nixos`, and move the generated hardware module into the variant directory you install. Put the variant name (`mango` or `plasma`) in `/mnt/etc/nixos/profile` and the stage (`base`, `apps`, or `full`) in `/mnt/etc/nixos/stage`; the hostname alias `nixbox` builds that variant.

```sh
scp -r flake.nix flake.lock profile stage common nixos-mango nixos-plasma dotfiles flakes \
  root@<iso-ip>:/mnt/etc/nixos/
# on the live ISO:
mv /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/nixos-mango/
rm /mnt/etc/nixos/configuration.nix
rm -f /mnt/etc/nixos/nixos-plasma/hardware-configuration.nix   # a foreign one from the repo
echo mango > /mnt/etc/nixos/profile
echo base > /mnt/etc/nixos/stage        # install apps and built packages after boot
```

The Nix files are listed below for reference (shared ones in `common/`, Mango ones in `nixos-mango/`). The install commands
use the repository's root flake (`flake.nix`); there are no per-configuration flakes.

#file("configuration.nix")
#raw(read("../../nixos-mango/configuration.nix"), lang: "nix", block: true)

#file("flake.nix")
#raw(read("../../flake.nix"), lang: "nix", block: true)

#file("home.nix")
#raw(read("../../nixos-mango/home.nix"), lang: "nix", block: true)

#file("desktop.nix")
#raw(read("../../nixos-mango/desktop.nix"), lang: "nix", block: true)

#file("home-packages.nix")
#raw(read("../../nixos-mango/home-packages.nix"), lang: "nix", block: true)

#file("packages.nix")
#raw(read("../../nixos-mango/packages.nix"), lang: "nix", block: true)

#file("nixos-mango/post-install.nix")
#raw(read("../../nixos-mango/post-install.nix"), lang: "nix", block: true)

#file("nixos-mango/built-packages.nix")
#raw(read("../../nixos-mango/built-packages.nix"), lang: "nix", block: true)

#file("common/brave.nix")
#raw(read("../../common/brave.nix"), lang: "nix", block: true)

#file("common/base.nix")
#raw(read("../../common/base.nix"), lang: "nix", block: true)

#file("common/vars.nix")
#raw(read("../../common/vars.nix"), lang: "nix", block: true)

#file("common/hardware-intel-laptop.nix")
#raw(read("../../common/hardware-intel-laptop.nix"), lang: "nix", block: true)

#file("common/home.nix")
#raw(read("../../common/home.nix"), lang: "nix", block: true)

#file("common/home-packages.nix")
#raw(read("../../common/home-packages.nix"), lang: "nix", block: true)

#file("common/post-install.nix")
#raw(read("../../common/post-install.nix"), lang: "nix", block: true)

#file("common/built-packages.nix")
#raw(read("../../common/built-packages.nix"), lang: "nix", block: true)

#file("common/packages.nix")
#raw(read("../../common/packages.nix"), lang: "nix", block: true)

#file("common/firefox.nix")
#raw(read("../../common/firefox.nix"), lang: "nix", block: true)

#note[Mango reads `~/.config/mango/config.conf` *instead of* its shipped example, so every bind you do not list does not exist.
The module validates the generated file at build time; a typo fails the rebuild, not your login.]

= Login, keyring, password managers

*How it works.* The initrd asks for the LUKS passphrase and keeps it in the kernel keyring. greetd logs `m` in without
asking (`initial_session`), and a PAM session rule (`pam_fde_boot_pw`) hands that passphrase to gnome-keyring, which uses it as
the password of the `login` keyring (created on first login). Brave and Bitwarden Desktop store their secrets there,
so they never prompt. Firefox, its extensions and the Proton apps need nothing from it.

*Rules.* LUKS passphrase = login password of `m` (also used by `sudo` and the Noctalia lock screen). Do not set an empty user password. If you change the password later, the keyring keeps the old one.

*Test after the first login* (should print `b false`):

```sh
busctl --user get-property org.freedesktop.secrets /org/freedesktop/secrets/collection/login \
  org.freedesktop.Secret.Collection Locked
```

#warn[This PAM trick is community-documented (NixOS Discourse, jdw.codeberg.page), not part of NixOS itself. The config evaluates and the PAM stack has the right order (inject passphrase, then unlock keyring), but it has not been run on hardware.
If Brave or Bitwarden ask for a keyring password, use the fallback: run `nix shell nixpkgs#seahorse -c seahorse`, create a keyring
named _Login_ with an *empty* password and make it the default. At rest it is then unencrypted inside your home directory,
which sits on the LUKS volume anyway. If the keyring password is wrong, first back up the
whole `~/.local/share/keyrings` directory. Move the existing directory aside, log in again to
create one new `login` keyring, then import any required secrets from the backup. This also
removes a stale second default keyring that applications could otherwise select.]

= Install

```sh
cd /mnt/etc/nixos
git init && git add -A                   # flakes ignore untracked files
swapon --show                            # temporary swap file and zram still active?
nixos-install --flake /mnt/etc/nixos#nixbox-mango --no-root-passwd --max-jobs 1
nixos-enter --root /mnt -c "printf '%s\n' 'm:PASSWORD' | chpasswd"   # m: same string as the LUKS passphrase
swapoff /mnt/.installer-swap && rm /mnt/.installer-swap
reboot                                   # remove the USB stick
```

`--max-jobs 1` limits parallel builds (RAM per compiler job); downloads from the caches are not affected.
`--no-root-passwd` is intentional: the configuration locks root (`hashedPassword = "!"`); use `sudo` from `m`.

Boot: type the LUKS passphrase, Mango starts by itself. Noctalia starts via Mango's `exec_once`;
`SUPER + d` opens its launcher, `SUPER + Return` a terminal, `SUPER + Shift + Return` Double Commander. Then run the keyring test above.

= Post install

After a base install (stage `base`), run these two steps in order on the installed system, connected to the network, as `m` (not root):

```sh
cd ~/nixos
./install-heavy-apps.sh                 # stage -> apps
./install-built-packages.sh             # stage -> full
```

The first script installs the large nixpkgs applications and changes `stage` to `apps`; the second installs local flakes, customized builds, and optional unfree apps, then changes `stage` to `full`. `./post-install.sh` remains an alias for the first step. If a step fails, its stage is restored and the running system remains unchanged, so retry the failed script. Extra arguments are passed to nh, for example `./install-heavy-apps.sh -- --max-jobs 2`. Afterwards reload Mango with `SUPER + r`.

#note[Until the built-packages step, Mango's `SUPER + Shift + Return` (Double Commander), local flakes, and optional unfree apps are not installed. Terminal (`SUPER + Return`), Nautilus, Firefox, Brave and the launcher work from the base install.]

= After the first boot

Flakes do not read `/etc/nixos`. The install script already moved the repository to `~/nixos` (this is also where `nh` looks for it). After a manual install do it yourself and put the repo on a remote:

```sh
sudo mv /etc/nixos ~/nixos && sudo chown -R "$USER": ~/nixos
cd ~/nixos && git add -A && git commit -m "initial system"
nh os switch                                 # alias: rebuild; picks the nixbox entry via ./profile
```

#table(
  columns: (auto, 1fr), stroke: 0.4pt + luma(170), inset: 4.5pt,
  [*Task*], [*Command*],
  [apply changes (system and Home Manager)], [`nh os switch` (alias `rebuild`), then `SUPER + r` to reload Mango],
  [try without a boot entry], [`nh os test`],
  [update everything], [`nh os switch --update` (alias `update`)],
  [update one input only], [`nix flake update noctalia`],
  [generations / rollback], [`nixos-rebuild list-generations`, `sudo nixos-rebuild switch --rollback`],
  [clean old generations], [automatic weekly (`programs.nh.clean`); manual: `nh clean all --keep-since 14d --keep 5`],
  [find an option], [search.nixos.org (options) and Home Manager option search; `man configuration.nix`],
)

#note[*Changing the password:* change the LUKS passphrase (`sudo cryptsetup luksChangeKey /dev/disk/by-partlabel/nixos`) and the password of `m` (`passwd`) to the same new string. The keyring keeps the old one: move `~/.local/share/keyrings` aside and log in again to create a new `login` keyring.]

= If something breaks

#set text(size: 9.5pt)
- *Warnings "unknown experimental feature '='", "...'extra-substituters'":* the config lines were joined into one. Redo the `nix.conf` step above (`unset NIX_CONFIG` first) and check with `nix config show`.
- *Installer freezes or the screen stops (RAM full):* look at `swapon --show` and `free -h` from a second TTY or over SSH. If needed, hard-reset, then redo `cryptsetup open`, the mounts and the temporary swap steps; or simply rerun `install.sh`; whatever was already downloaded or built stays in `/mnt/nix/store`, so the retry resumes.
- *"path ... is not tracked by Git"* or a file seems ignored: `git add` it.
- *Passphrase asked twice or no auto-login:* systemd is now the only initrd implementation; check `journalctl -u greetd -b`.
- *Black screen or back at the same screen:* greetd restarts the session, and tty1 has no getty. Switch to tty2 with Ctrl+Alt+F2, log in as `m`, then run `sudo systemctl stop greetd` to stop the restart loop while you inspect `journalctl -u greetd -b` or try `mango`. Run `sudo systemctl start greetd` to resume the graphical login.
- *No bar:* run `noctalia` in a terminal and read the error. A Noctalia config error is also caught at build time.
- *Noctalia compiles for ages:* the Cachix key is missing or the input has `follows`; check `nix.settings` above.
- *Option names used here:* `programs.mango`, `wayland.windowManager.mango`, `programs.noctalia`. Noctalia v5 (this guide) is the native rewrite; the old Quickshell version (`noctalia-shell`) is different.

#v(1fr)
#text(8pt, fill: luma(90))[Sources: docs.noctalia.dev (NixOS, Mango, IPC, FAQ); mangowm/mango `nix/` modules; Home Manager manual; wiki.nixos.org (Mango, Greetd); NixOS Discourse thread "Automatically unlocking the gnome-keyring using LUKS key with greetd"; jdw.codeberg.page/blog/nixos-automatic-login.]
