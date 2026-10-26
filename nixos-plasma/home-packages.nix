{ pkgs, ... }:

{
  # Plasma-only user packages (the shared set is in ../common/home-packages.nix).
  home.packages = [
    (import ../common/brave.nix {
      inherit pkgs;
      passwordStore = "kwallet6";
    })
  ]
  ++ (with pkgs; [
    kdePackages.dolphin
    kdePackages.dolphin-plugins
    kdePackages.kdenetwork-filesharing
    kdePackages.kio-extras
  ]);
}
