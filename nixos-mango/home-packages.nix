{ pkgs, ... }:
{
  # Mango-only base user packages (the shared set is in ../common/home-packages.nix,
  # the large applications are in ./apps.nix and ./built.nix).
  home.packages = [
    (import ../common/brave.nix {
      inherit pkgs;
      passwordStore = "gnome-libsecret";
    })
  ]
  ++ (with pkgs; [
    adwaita-icon-theme
    nautilus
    trash-cli
    udiskie
  ]);
}
