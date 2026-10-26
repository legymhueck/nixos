# NixOS

Personal, reproducible NixOS workstation configuration: one flake, two alternative desktops, Home Manager, shared dotfiles, local packages and an installer that separates the base system, large cached applications, and local/unfree packages.

## Layout

| Path | Purpose |
| --- | --- |
| `flake.nix`, `flake.lock` | Single entry point, all inputs pinned. `nixosConfigurations.nixbox` is an alias for the variant named in `profile`. A real `nixbox-<variant>` exists only where `nixos-<variant>/hardware-configuration.nix` exists; `nixbox-<variant>-eval` (and `-apps-eval`, `-base-eval`) twins evaluate without it (CI only, never deploy). Also exports the local packages (`nix build .#hylki`), a dev shell with the linters (`nix develop`) and the formatter |
| `profile` | `mango` or `plasma`: which variant `nixbox` builds (written by the installer) |
| `stage` | `base`, `apps` or `full`: package layer currently active (written by the install scripts, default `full`) |
| `common/` | Shared by both variants: `vars.nix` (user, host, Btrfs mounts), `options.nix` (`nixbox.stage`), `base.nix` (system), `hardware-intel-laptop.nix` (Intel/ThinkPad specifics), `packages.nix`, `home.nix` (shell, git, starship, ...), `home-packages.nix` (small base set), `apps.nix` (large nixpkgs applications, `apps` stage), `built.nix` (local packages, customized builds, unfree apps, `full` stage), `scripts.nix`, `firefox.nix`, `brave.nix` |
| `nixos-mango/` | MangoWM + Noctalia (greetd autologin); `cursor.nix` (`nixbox.cursor`), `desktop.nix`, and its own `apps.nix` / `built.nix` |
| `nixos-plasma/` | KDE Plasma 6 + SDDM |
| `dotfiles/` | Files that Home Manager links (kitty, mc, starship, LibreOffice, ...) |
| `pkgs/` | Local packages (`bibox`, `cornelsen-offline-lernen`, `doublecmd-qt6`, `hylki`, `mtplayer`, `revpdf`), added to `pkgs` by an overlay |
| `scripts/` | Shell scripts, installed as commands by `common/scripts.nix` |
| `install.sh` | Base install: disk-wiping installer for the NixOS minimal ISO |
| `install-stage.sh` | Post-install steps: `apps` (large applications from nixpkgs), then `full` (local packages, customized builds, optional unfree apps) |
| `docs/` | Install guide (Typst), Git handout, tips; `docs/tips/commands.md` is a cheat sheet of everyday commands |
| `.github/workflows/` | CI: lint and evaluation of both variants |

Both variants use host name `nixbox` and user `m`. They are alternatives, not two hosts.

## Install

The install is split into three stages so the local and unfree package set is activated separately from the large nixpkgs applications:

| Part | Where | What it does |
| --- | --- | --- |
| **1. Base install** | live ISO, `install.sh` | Installs the complete bootable system and small desktop package set. Writes `stage` = `base`. |
| **2. Large applications** | installed system, `./install-stage.sh apps` | Switches `stage` to `apps` and activates the large nixpkgs applications from their normal binary caches. |
| **3. Local and unfree packages** | installed system, `./install-stage.sh full` | Switches `stage` to `full` and activates the local packages, customized builds and optional unfree applications. |

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

`install.sh` always installs only the base stage; packages from steps 2 and 3 are intentionally installed after first boot.

### 2. Post install

After the reboot and the first login, connect to the network and run on the installed system, as your normal user:

```sh
cd ~/nixos
./install-stage.sh apps
./install-stage.sh full
```

Run the steps in order. `apps` applies the large nixpkgs application set and changes `stage` to `apps`; `full` installs local packages and unfree apps and changes `stage` to `full`. A failed step reverts the stage, so the active system remains unchanged and you can retry. Extra arguments go to nh, e.g. `./install-stage.sh apps -- --max-jobs 2`. Until the final step, local packages and optional unfree apps (including Mango's Double Commander) are not installed.

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

After both post-install steps the stage is `full`; these commands apply and update everything.

```sh
nh os switch            # alias: rebuild. Apply the configuration
nh os switch --update   # alias: update. Update all inputs, then apply
nh os test              # activate without a boot entry
```

Old generations are removed weekly (`programs.nh.clean`, keeps 5 and 14 days). Check with `nix flake check` (lint, evaluation of all configurations and packages) and `nix eval .#nixosConfigurations.nixbox-mango-eval.config.system.build.toplevel.drvPath` (same for `-plasma-eval`, `-apps-eval`, `-base-eval`) before pushing; CI runs the same. Format with `nix fmt`. `nix develop` gives a shell with statix, deadnix, nixfmt, shellcheck and shfmt.

### Contributor notes

- The unfree allowlist is intentionally explicit in `common/base.nix`; do not widen it to `allowUnfree = true` unless a package truly requires it.
- A new large nixpkgs app goes into `common/apps.nix` (or the variant's `apps.nix`); a local package (`pkgs/<name>/package.nix`, registered in `pkgs/default.nix`), a customized build or an unfree app goes into `built.nix`.
- CI runs `nix fmt` and `nix flake check` and refuses a dirty checkout after formatting, so the repo is kept consistent before merge.

## Reproducibility

- Every input is locked in `flake.lock`; `nix shell nixpkgs#...` and `<nixpkgs>` use the system's own nixpkgs revision (registry + `nixPath`).
- No package is pinned to another nixpkgs revision. If one breaks on unstable, add a `nixpkgs-stable` input and take only that package from it (overlay in `common/base.nix`); drop it again once unstable is cached.
- Packages are wrapped, not rebuilt, wherever possible (VeraCrypt icon). Unfree packages are never in the binary cache, so VeraCrypt still compiles locally.
- The Noctalia official and community plugin sources are pinned in `flake.lock` and exposed to Noctalia as immutable Nix store paths, so plugin code is not fetched at runtime.

## Notes

- `nixos-mango/hardware-configuration.nix` in the repo belongs to the current machine; the installer replaces it for a new one. Never deploy without the generated module of the target.
- The `stage` file in the repo is `full`; only the installer writes `base` into the copy on the target machine.
- Do not change `system.stateVersion` / `home.stateVersion` during routine updates.
- More detail: `docs/install_guide/nixos-install-guide.typ` (compile with `typst compile docs/install_guide/nixos-install-guide.typ --root .`), `AGENTS.md`.
