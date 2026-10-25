# NixOS

Personal, reproducible NixOS workstation configuration: one flake, two alternative desktops, Home Manager, shared dotfiles, local package flakes and a two-step installer (base install from the ISO, post install on the installed system).

## Layout

| Path | Purpose |
| --- | --- |
| `flake.nix`, `flake.lock` | Single entry point, all inputs pinned. `nixosConfigurations.nixbox` is an alias for the variant named in `profile`. A real `nixbox-<variant>` exists only where `nixos-<variant>/hardware-configuration.nix` exists; `nixbox-<variant>-eval` twins evaluate without it (CI only, never deploy) |
| `profile` | `mango` or `plasma`: which variant `nixbox` builds (written by the installer) |
| `stage` | `base` or `full`: whether the post-install modules are part of the build (written by `install.sh` / `post-install.sh`, default `full`) |
| `common/` | Shared by both variants: `vars.nix` (user and host name), `base.nix` (system), `hardware-intel-laptop.nix` (Intel/ThinkPad specifics), `packages.nix`, `home.nix` (shell, git, starship, ...), `home-packages.nix` (small base set), `post-install.nix` (large applications, local builds), `firefox.nix`, `brave.nix` |
| `nixos-mango/` | MangoWM + Noctalia (greetd autologin); `post-install.nix` holds the Mango-only large applications |
| `nixos-plasma/` | KDE Plasma 6 + SDDM |
| `dotfiles/` | Files that Home Manager links (kitty, mc, scripts, starship, ...) |
| `flakes/` | Local package flakes: `bibox`, `cornelsen_offline_lernen`, `hylki`, `mtplayer`, `revpdf` |
| `install.sh` | Base install: disk-wiping installer for the NixOS minimal ISO |
| `post-install.sh` | Post install: run on the installed system, adds the large applications |
| `docs/` | Install guide (Typst), Git handout, tips |
| `.github/workflows/` | CI: lint and evaluation of both variants |

Both variants use host name `nixbox` and user `m`. They are alternatives, not two hosts.

## Install

The installation has two parts, so that nothing large is built on the live ISO (it keeps its build directories in RAM):

| Part | Where | What it does |
| --- | --- | --- |
| **1. Base install** | live ISO, `install.sh` | Partitions, encrypts and formats the disk, installs the complete system (services, desktop, login, Brave/Firefox policies, ...) and a small package set from the binary cache. Writes `stage` = `base`. |
| **2. Post install** | installed system, `post-install.sh` | Switches `stage` to `full` and runs `nh os switch`: large applications (LibreOffice, GIMP, Kdenlive, IDEs, ...), VeraCrypt and the local package flakes, which are compiled or fetched here. |

### 1. Base install

Boot the NixOS minimal ISO (UEFI), connect to the network (`nmtui`), then:

```sh
git clone https://github.com/legymhueck/nixos.git
cd nixos
lsblk                                    # identify the target disk
sudo ./install.sh mango  /dev/nvme0n1    # MangoWM + Noctalia
sudo ./install.sh plasma /dev/nvme0n1    # KDE Plasma 6
reboot
```

The script copies the complete checkout (with `.git`) to `~/nixos`, so it is a working clone afterwards (set the remote or keep it local). It **erases the whole disk** after you type `YES`, and refuses disks with mounted partitions (the installer stick). It creates GPT/EFI, LUKS2 and Btrfs subvolumes (`@`, `@home`, `@nix`, `@log`, zstd) and installs. A temporary swap file is used only during the install and deleted at the end; the installed system uses zram.

The script asks for **one password**. It becomes the LUKS passphrase and the password of `m`. Root login is disabled (use `sudo`).

A third argument selects the stage: `sudo ./install.sh mango /dev/nvme0n1 full` installs everything in one go (the old behaviour) and there is no post install.

### 2. Post install

After the reboot and the first login, connect to the network and run on the installed system, as your normal user:

```sh
cd ~/nixos
./post-install.sh
```

It sets `stage` to `full`, applies the configuration with `nh os switch` and commits the change. It can be repeated; if the build fails, `stage` is set back to `base` and the running system stays unchanged. Extra arguments go to nh, e.g. `./post-install.sh -- --max-jobs 2`. Until it has run, Mango's `SUPER + Shift + Return` (Double Commander) and other apps listed in `common/post-install.nix` and `nixos-mango/post-install.nix` are not installed.

## Login (Mango)

1. Power on, type the disk passphrase.
2. The desktop starts by itself, no login screen (boot only; after a logout or compositor crash tuigreet asks for the password).
3. The keyring (Brave, Bitwarden, ...) is unlocked with the same passphrase automatically.
4. The lock screen asks for the same password.

So there is exactly one password. Plasma shows the SDDM login screen instead (KWallet needs the typed password).

### Changing the password

The disk passphrase and the account password must stay identical:

```sh
sudo cryptsetup luksChangeKey /dev/disk/by-partlabel/nixos
passwd
```

Afterwards move `~/.local/share/keyrings` aside and log in again once, so a new keyring with the new password is created.

## Daily use

After the post install the stage is `full` for good; these commands apply and update everything.

```sh
nh os switch            # alias: rebuild. Apply the configuration
nh os switch --update   # alias: update. Update all inputs, then apply
nh os test              # activate without a boot entry
```

Old generations are removed weekly (`programs.nh.clean`, keeps 5 and 14 days). Check with `nix flake check` (lint) and `nix eval .#nixosConfigurations.nixbox-mango-eval.config.system.build.toplevel.drvPath` (same for `-plasma-eval`) before pushing; CI runs the same. Format with `nix fmt`.

## Reproducibility

- Every input is locked in `flake.lock`; `nix shell nixpkgs#...` and `<nixpkgs>` use the system's own nixpkgs revision (registry + `nixPath`).
- `pkgs.stable` (nixos-26.05) is available through an overlay for packages that break on unstable.
- Packages are wrapped, not rebuilt, wherever possible (VeraCrypt icon). Unfree packages are never in the binary cache, so VeraCrypt still compiles locally.
- The Noctalia official and community plugin sources are pinned in `flake.lock` and exposed to Noctalia as immutable Nix store paths, so plugin code is not fetched at runtime.

## Notes

- `nixos-mango/hardware-configuration.nix` in the repo belongs to the current machine; the installer replaces it for a new one. Never deploy without the generated module of the target.
- The `stage` file in the repo is `full`; only the installer writes `base` into the copy on the target machine.
- Do not change `system.stateVersion` / `home.stateVersion` during routine updates.
- More detail: `docs/install_guide/nixos-install-guide.typ` (compile with `typst compile docs/install_guide/nixos-install-guide.typ --root .`), `AGENTS.md`.
