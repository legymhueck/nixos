{
  lib,
  pkgs,
  osConfig,
  ...
}:

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
  # Mango-only applications, active from the apps stage on (the shared set is
  # in ../common/apps.nix). Unfree apps and Double Commander are in ./built.nix.
  config = lib.mkIf (osConfig.nixbox.stage != "base") {
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
  };
}
