# Repository Guide for Agents

## Purpose and layout

Two alternative NixOS configurations (Mango + Noctalia, KDE Plasma 6) that share `common/`, one root flake, shared dotfiles, four local package flakes and a single installer.

- `flake.nix` / `flake.lock`: only flake and only lock file (the local package flakes have their own locks). `nixosConfigurations.nixbox` is an alias for `nixbox-<profile>`, where `profile` is read from the file `profile` (default `mango`). Real `nixbox-<variant>` configurations exist only if `nixos-<variant>/hardware-configuration.nix` exists; `nixbox-<variant>-eval` (full stage) and `nixbox-<variant>-base-eval` (base stage) twins use a `/dev/null` filesystem fallback (`evaluationHardware`) and are for CI/`nix eval` only. `checks.x86_64-linux.lint` runs statix, deadnix and shellcheck (`install.sh`, `post-install.sh`, the dotfile scripts).
- `common/vars.nix`: user and host name, read by the flake, the modules and `install.sh`. `common/hardware-intel-laptop.nix`: Intel/ThinkPad specifics (`nixbox.batteryThresholds` option, fprintd, thermald, iHD/QSV, SOF firmware), imported by each variant's `configuration.nix`.
- `common/base.nix`: shared system module (nix settings, nh, boot, LUKS, Btrfs, zram, locale, snapper, services, Brave policies, `pkgs.stable` overlay). `common/packages.nix`: system packages (imported by `base.nix`). `common/home.nix`: Home Manager (bash, starship, zoxide, eza, git, gh, foot, scripts, mc/kitty files); it imports `common/home-packages.nix` (small base set), `common/firefox.nix` and, in the full stage, `common/post-install.nix` (large applications, patched packages, VeraCrypt wrapper, local package flakes). `common/brave.nix`: function building Brave with a password store.
- `nixos-mango/`: `configuration.nix` (imports `common/base.nix`, the hardware module + `packages.nix`; greetd autologin at boot only, tuigreet afterwards; keyring PAM), `home.nix` (imports `common/home.nix`, `desktop.nix`, `home-packages.nix`, and `post-install.nix` in the full stage), generated `hardware-configuration.nix`.
- `nixos-plasma/`: `configuration.nix`, `home.nix`, `home-packages.nix`.
- `dotfiles/`: sources linked by Home Manager. Nix files use paths relative to the module, so keep them in sync with layout changes.
- `install.sh`: the base installer (`./install.sh <mango|plasma> <disk> [base|full]`, default `base`). `post-install.sh`: run by the user on the installed system, sets `stage` to `full` and runs `nh os switch`.
- `stage` (file, `base` or `full`, default `full` when missing): read by the flake and passed as the `stage` argument to the NixOS modules (`specialArgs`) and Home Manager (`extraSpecialArgs`). `common/home.nix` and `nixos-mango/home.nix` import `common/post-install.nix` / `nixos-mango/post-install.nix` only when `stage == "full"`.
- `docs/install_guide/nixos-install-guide.typ` reads files from the repo (`../../...`); compile from the repo root.

## Configuration invariants

- The generated `hardware-configuration.nix` belongs to the target installation. The one committed under `nixos-mango/` belongs to the current machine. Without it the real configuration fails to evaluate on purpose (no silent `/dev/null` root); use the `-eval` outputs for checks. Never deploy without the generated module.
- `system.stateVersion` and `home.stateVersion` are `26.05`. Do not change them in routine updates.
- The root flake intentionally does not set `inputs.noctalia.inputs.nixpkgs.follows` (needed for the Noctalia Cachix cache).
- `console.earlySetup = true` keeps the German keymap at the LUKS prompt. `GTK_THEME` / `SAL_USE_VCLPLUGIN` are Mango-only (set in `nixos-mango/configuration.nix`).
- No persistent swap file. zram only; `install.sh` uses a temporary swap file during `nixos-install` and removes it.
- Root login is disabled in `common/base.nix`; the installer sets only the password of `m`.
- Mango login: LUKS passphrase = password of the user. greetd `initial_session` autologs in at boot only; `default_session` is tuigreet so a crashed or logged-out session never lands unlocked. `pam_fde_boot_pw` passes the passphrase to gnome-keyring. Do not set an empty user password.
- `programs.nh` replaces `nix.gc`; do not enable both. nh looks for the flake in `/home/m/nixos`.
- Cursor theme/size are defined once in `nixos-mango/configuration.nix` and read back in `desktop.nix` via `osConfig`.
- Brave policies go to `/etc/brave/policies/managed/brave.json` (not `programs.chromium`).
- `install.sh` copies the whole checkout (with `.git`) to the target, writes `profile`, `stage` and the generated hardware module, and commits. No copy list to maintain.
- Base vs post install: the system level (NixOS modules, services, system packages) is always complete in the base install. Only Home Manager packages are split: `home-packages.nix` files = small, cached, needed for a usable desktop; `post-install.nix` files = large applications and anything built locally (VeraCrypt, package flakes, `overrideAttrs`). Do not move something that the desktop config launches or depends on (Firefox, Brave, Nautilus, qt6ct, kitty/foot) into a post-install module. The `stage` file committed in the repo stays `full`.

## Workflows

```sh
nix eval .#nixosConfigurations.nixbox-mango-eval.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.nixbox-plasma-eval.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.nixbox-mango-base-eval.config.system.build.toplevel.drvPath   # base stage, same for plasma
nix flake check                   # lint: statix, deadnix, shellcheck
nix fmt                           # nixfmt on all Nix files
typst compile docs/install_guide/nixos-install-guide.typ --root .
nh os switch      # on the installed system
```

Flakes only see git-tracked files: `git add` new files before evaluating.

## Notes for changes

- Put shared things in `common/`; keep a variant directory for what is truly desktop-specific.
- When adding a Home Manager module or renaming a file, update the `imports` (`common/base.nix` / `common/home.nix` for shared modules, the variant files for the rest) and the Typst listings.
- Local package flakes declare `x86_64-linux`; `hylki` also `aarch64-linux`. MTPlayer uses Temurin 21; keep it aligned with its `buildInputs`.
- Follow the active Firefox module API in `common/firefox.nix` (`profiles.default.settings` plus `policies`).
- Prefer wrapping a finished package (`symlinkJoin`) over `overrideAttrs`, which forces a local rebuild.
