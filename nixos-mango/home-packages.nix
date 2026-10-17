{ pkgs, inputs, ... }:

{
  # Mango-only user packages (the shared set is in ../common/home-packages.nix).
  home.packages = [
    (import ../common/brave.nix {
      inherit pkgs;
      passwordStore = "gnome-libsecret";
    })
  ]
  ++ (with pkgs; [
    adwaita-icon-theme
    bitwarden-desktop
    flameshot
    gpu-screen-recorder
    intellij-idea
    kdePackages.kdeconnect-kde
    nautilus
    proton-pass
    pycharm
    trash-cli
    tutanota-desktop
    udiskie
    whatsie
  ])
  ++ [
    inputs.doublecmd-qt6.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
