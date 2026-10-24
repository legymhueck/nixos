# Typst Compilation Guide

Typst compilation commands for documents in this repository.

## NixOS Install Guide

The install guide reads files across the repository, so the Typst root must point to the repo root (`--root .` or `--root ..`).

### From the repository root

```sh
typst compile docs/install_guide/nixos-install-guide.typ --root .
```

### From docs/

```sh
typst compile ./install_guide/nixos-install-guide.typ --root ..
```

## Git Basics Tutorial

### From the repository root

```sh
typst compile docs/git_tutorial/git-basics.typ docs/git_tutorial/git-basics.pdf
```

### From docs/git_tutorial

```sh
typst compile ./git-basics.typ ./git-basics.pdf
```
