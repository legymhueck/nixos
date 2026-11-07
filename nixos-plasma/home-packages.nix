{ pkgs, ... }:

{
  # Plasma-only user packages (the shared set is in ../common/home-packages.nix).
  home.packages = with pkgs; [
    kdePackages.dolphin
    kdePackages.dolphin-plugins
    kdePackages.kdenetwork-filesharing
    kdePackages.kio-extras
  ];
}
