{ pkgs, ... }:

let
  tutanotaDesktopEntry = pkgs.makeDesktopItem {
    name = "tutanota-desktop";
    desktopName = "Tuta";
    comment = "The desktop client for Tuta, the secure e-mail, calendar and drive service.";
    genericName = "Mail Client";
    categories = [ "Network" ];
    exec = "tutanota-desktop %U";
    icon = "tutanota-desktop";
    mimeTypes = [ "x-scheme-handler/mailto" ];
    startupWMClass = "Tuta";
    terminal = false;
  };
in
{
  # Mango-only applications for the optional apps stage. The unfree apps and
  # local Double Commander flake are installed in ./built-packages.nix.
  home.packages = with pkgs; [
    flameshot
    gpu-screen-recorder
    kdePackages.kdeconnect-kde
    qview
    tutanota-desktop
    whatsie
  ];

  xdg.dataFile."applications/tutanota-desktop.desktop".source =
    "${tutanotaDesktopEntry}/share/applications/tutanota-desktop.desktop";

}
