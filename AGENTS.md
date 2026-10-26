# Repository Guide for Agents

Two alternative NixOS desktops (Mango + Noctalia, KDE Plasma 6) for one laptop (host `nixbox`, user `m`): one root flake, shared `common/`, variant dirs `nixos-mango/` and `nixos-plasma/`, local packages in `pkgs/`, scripts in `scripts/`, installer `install.sh` + `install-stage.sh`. README.md has the full layout.

## How it fits together

- `nixosConfigurations.nixbox` = `nixbox-<file ./profile>`. A real `nixbox-<variant>` exists only if `nixos-<variant>/hardware-configuration.nix` exists (the flake adds it; the one committed under `nixos-mango/` belongs to this machine). The `-eval`, `-apps-eval`, `-base-eval` twins use a `/dev/null` stand-in: for checks only, never deploy.
- Module arguments `inputs` and `vars` (`common/vars.nix`) come from `specialArgs`/`extraSpecialArgs`; never `import` vars.nix in modules.
- Install stages: the file `./stage` (`base`/`apps`/`full`, committed as `full`) sets the option `nixbox.stage`. The system level is complete in every stage; only Home Manager packages are split. `home-packages.nix` = small, cached, needed for a usable desktop (never move Firefox, Brave, Nautilus, qt6ct, kitty/foot out of it). `apps.nix` = large cached nixpkgs apps (`stage != "base"`). `built.nix` = everything compiled locally or unfree: `pkgs/`, wrappers, unfree apps (`stage == "full"`). Stage modules are always imported and wrap their `config` in `lib.mkIf`.
- One `pkgs` everywhere (`useGlobalPkgs`); overlays live in `common/base.nix`. No package is pinned to another nixpkgs revision; add a pin only if unstable is broken and uncached, and remove it once it is cached.

## Invariants

- `system.stateVersion` (in `common/base.nix`) and `home.stateVersion` stay `26.05`.
- No `inputs.noctalia.inputs.nixpkgs.follows` (the Noctalia Cachix cache needs its own pin).
- Unfree packages only via the explicit allowlist in `common/base.nix` (names as `lib.getName` returns them).
- Mango login: LUKS passphrase = user password. greetd autologin (`initial_session`) at boot only, tuigreet afterwards; `pam_fde_boot_pw` unlocks gnome-keyring. Never set an empty password; root stays locked.
- zram only, no swap file. `programs.nh` cleans; never also enable `nix.gc`.
- Cursor: set once as `nixbox.cursor` in `nixos-mango/configuration.nix`; `desktop.nix` reads it via `osConfig` for dconf, Mango and `gtk.cursorTheme` (XWayland apps such as pCloud read the cursor only from GTK's settings.ini).
- Brave policies go to `/etc/brave/policies/managed/brave.json`, not `programs.chromium`.
- `install.sh` copies the whole checkout and commits with `git add -A` (`.gitignore` covers `result*`).

## Workflows

```sh
nix flake check   # statix, deadnix, shellcheck + evaluation of all outputs
nix eval .#nixosConfigurations.nixbox-mango-eval.config.system.build.toplevel.drvPath   # also plasma, -apps-eval, -base-eval
nix eval .#nixosConfigurations.nixbox-mango.config.system.build.toplevel.drvPath        # the real system
nix build .#<pkg> # a local package from pkgs/
nix fmt           # nixfmt; CI fails on unformatted files
typst compile docs/install_guide/nixos-install-guide.typ --root .   # then delete the PDF
```

Flakes only see git-tracked files: `git add` new files before evaluating. Users rebuild with `nh os switch`.

## Making changes

- Shared things go in `common/`; a variant dir only holds what is desktop-specific.
- New or renamed module: update the `imports`, the file checks in `install.sh`, and the `#raw(read(...))` listings in the Typst guide.
- New local package: `pkgs/<name>/package.nix` (`callPackage` style, `meta.platforms`), a line in `pkgs/default.nix`, use it in a `built.nix`, add it to the allowlist if unfree. Non-fetch sources become root flake inputs.
- New script: `scripts/<name>.sh` plus a `mkScript` line with its runtime dependencies in `common/scripts.nix`.
- New user-facing command, alias or script: add it to `docs/tips/commands.md`.
- Prefer wrapping a finished package (`symlinkJoin`) over `overrideAttrs`, which forces a local build.
- Firefox: `profiles.default.settings` plus `policies` in `common/firefox.nix`.
