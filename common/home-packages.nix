{ pkgs, ... }:

{
  # Base user packages shared by the Mango and Plasma variants: small, all
  # from the binary cache, enough for a usable desktop right after the base
  # install. The large applications are in ./post-install.nix and are added by
  # post-install.sh. Desktop-specific ones are in nixos-<variant>/home-packages.nix.
  # starship, zoxide, eza and the GitHub CLI come from programs.* in common/home.nix.
  home.packages = with pkgs; [
    bat
    btop
    fd
    fzf
    helix
    micro
    kitty
    lsof
    p7zip
    ripgrep
    tealdeer
    unzip
    wget
    zip
    wl-clipboard
    qt6Packages.qt6ct
    kdePackages.breeze-icons
    kdePackages.kimageformats
    kdePackages.okular
    mpv
    pwvucontrol
    sshfs
    inter
    liberation_ttf
    fira-code
  ];
}
