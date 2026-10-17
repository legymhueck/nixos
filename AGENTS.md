# Repository Guide for Agents

## Purpose and layout

Two alternative NixOS configurations (Mango + Noctalia, KDE Plasma 6) that share `common/`, one root flake, shared dotfiles, four local package flakes and a single installer.

- `flake.nix` / `flake.lock`: only flake and only lock file (the local package flakes have their own locks). `nixosConfigurations.nixbox` is an alias for `nixbox-<profile>`, where `profile` is read from the file `profile` (default `mango`).
- `common/base.nix`: shared system module (nix settings, nh, boot, LUKS, Btrfs, zram, locale, snapper, services, Brave policies, `nixbox.batteryThresholds` option, `pkgs.stable` overlay). `common/packages.nix`: system packages (imported by `base.nix`). `common/home.nix`: Home Manager (bash, starship, zoxide, eza, git, gh, foot, scripts, mc/kitty files); it imports `common/home-packages.nix` (user packages) and `common/firefox.nix`. `common/brave.nix`: function building Brave with a password store.
- `nixos-mango/`: `configuration.nix` (imports `common/base.nix` + `packages.nix`, greetd autologin, keyring PAM), `home.nix` (imports `common/home.nix`, `desktop.nix`, `home-packages.nix`), generated `hardware-configuration.nix`.
- `nixos-plasma/`: `configuration.nix`, `home.nix`, `home-packages.nix`.
- `dotfiles/`: sources linked by Home Manager. Nix files use paths relative to the module, so keep them in sync with layout changes.
- `install.sh`: the only installer (`./install.sh <mango|plasma> <disk>`).
- `docs/nixos-install-guide.typ` reads files from the repo; compile from the repo root.

## Configuration invariants

- The generated `hardware-configuration.nix` belongs to the target installation. The one committed under `nixos-mango/` belongs to the current machine. A clean checkout without it evaluates through the fallback in `flake.nix` (`evaluationHardware`), which is inactive when the file exists. Never deploy without the generated module.
- `system.stateVersion` and `home.stateVersion` are `26.05`. Do not change them in routine updates.
- The root flake intentionally does not set `inputs.noctalia.inputs.nixpkgs.follows` (needed for the Noctalia Cachix cache).
- `console.earlySetup = true` keeps the German keymap at the LUKS prompt. `GTK_THEME` / `SAL_USE_VCLPLUGIN` are Mango-only (set in `nixos-mango/configuration.nix`).
- No persistent swap file. zram only; `install.sh` uses a temporary swap file during `nixos-install` and removes it.
- Root login is disabled in `common/base.nix`; the installer sets only the password of `m`.
- Mango login: LUKS passphrase = password of `m`. greetd autologin, `pam_fde_boot_pw` passes the passphrase to gnome-keyring. Do not set an empty user password.
- `programs.nh` replaces `nix.gc`; do not enable both. nh looks for the flake in `/home/m/nixos`.
- Cursor theme/size are defined once in `nixos-mango/configuration.nix` and read back in `desktop.nix` via `osConfig`.
- Brave policies go to `/etc/brave/policies/managed/brave.json` (not `programs.chromium`).
- Keep the installer's copy list in sync when adding top-level directories (`install.sh` copies `flake.nix flake.lock common nixos-mango nixos-plasma dotfiles flakes`, writes `profile`).

## Workflows

```sh
nix eval .#nixosConfigurations.nixbox-mango.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.nixbox-plasma.config.system.build.toplevel.drvPath
statix check . && deadnix --fail --exclude "**/hardware-configuration.nix" .
bash -n install.sh && shellcheck install.sh dotfiles/scripts/.local/share/scripts/*.sh
typst compile docs/nixos-install-guide.typ --root .
nh os switch      # on the installed system
```

Flakes only see git-tracked files: `git add` new files before evaluating.

## Notes for changes

- Put shared things in `common/`; keep a variant directory for what is truly desktop-specific.
- When adding a Home Manager module or renaming a file, update the `imports` (`common/base.nix` / `common/home.nix` for shared modules, the variant files for the rest) and the Typst listings.
- Local package flakes declare `x86_64-linux`; `hylki` also `aarch64-linux`. MTPlayer uses Temurin 21; keep it aligned with its `buildInputs`.
- Follow the active Firefox module API in `common/firefox.nix` (`profiles.default.settings` plus `policies`).
- Prefer wrapping a finished package (`symlinkJoin`) over `overrideAttrs`, which forces a local rebuild.
