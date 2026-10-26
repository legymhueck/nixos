# Writing commit messages

A commit message explains a change to someone who reads `git log` later,
usually you in six months. Git basics are in `docs/git_tutorial/`.

## The shape

```text
Short summary in the imperative, about 50-72 characters

Body after one empty line, wrapped at about 72 characters. Say what
changed and why; the diff already shows how.
- Bullet points work well for several related changes.
```

- **Subject:** imperative mood, like a command: "Add Rnote", "Drop HandBrake
  pin", not "Added ..." or "Adds ...". No period at the end. Optionally prefix
  the area: `flake.lock: update inputs`, `pcloud: fix cursor`.
- **Body:** the reason. "Unstable now has a cached build" is worth more than
  "changed apps.nix". Mention issue links (`NixOS/nixpkgs#574140`).
- One commit per logical change when you can: easier to read and to undo.

## Examples from this repo

A routine update (the one you will write most often):

```sh
git commit -am "flake.lock: update inputs"
```

A small change, subject only:

```text
Add Rnote, remove MyPaint
```

A change that needs a reason:

```text
Set gtk.cursorTheme for XWayland apps

GTK reads the cursor from GSettings only on Wayland. X11 clients on
XWayland (pCloud's Electron) read GTK's settings.ini, which had no
cursor, so they fell back to the small Adwaita cursor.
```

A large change, grouped (commit 5cf0ab4, shortened):

```text
Restructure flake: local packages, typed stage option, fewer pins

Structure
- Replace the six local package flakes in flakes/ with pkgs/<name>/package.nix
  files loaded by one overlay.
- Add the typed option nixbox.stage set from ./stage.

Packages
- Drop the HandBrake and nixpkgs-stable pins: the regular unstable
  packages are cached.

Fixes
- Remove the broken XDG_XDG_PROJECTS_DIR_DIR entry in user-dirs.dirs.
```

## Trailers

Lines at the very end, after an empty line, in the form `Key: value`. Commits
made with an AI assistant carry one, for example
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Nixpkgs requires
`Assisted-by:` instead (see its CONTRIBUTING.md, "Automation/AI policy").

## Everyday commands

```sh
git status                    # what changed
git diff                      # the changes themselves
git add -A                    # stage everything (flakes only see tracked files)
git commit                    # opens your editor (micro) for subject + body
git commit -m "Subject"       # subject only
git push                      # send to GitHub
git commit --amend            # fix the last message (only before git push)
git log --oneline -10         # the last ten subjects
```
