{ pkgs, ... }:

{
  # Mango-only system packages (the shared set is in ../common/packages.nix).
  environment.systemPackages = with pkgs; [
    adw-gtk3
    breeze-hacked-cursor-theme
    kdiskmark
    wdisplays
    xwayland
  ];
}
