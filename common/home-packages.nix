{ pkgs, ... }:

{
  # Base user packages shared by the Mango and Plasma variants: small, all
  # from the binary cache, enough for a usable desktop right after the base
  # install. The large applications are in ./apps.nix and ./built.nix (later
  # install stages). Desktop-specific ones are in nixos-<variant>/home-packages.nix.
  # starship, zoxide, eza and the GitHub CLI come from programs.* in common/home.nix.
  home.packages = with pkgs; [
    bat
    btop
    fd
    fzf
    helix
    inter
    kdePackages.breeze-icons
    kdePackages.kimageformats
    kdePackages.okular
    kitty
    lsof
    micro
    mpv
    mupdf
    p7zip
    poppler-utils
    pwvucontrol
    qt6Packages.qt6ct
    ripgrep
    sshfs
    tealdeer
    unzip
    wget
    wl-clipboard
    zip
  ];
}
