{ config, pkgs, ... }:

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
  imports = [
    ../common/home.nix
    ./desktop.nix
    ./home-packages.nix
  ];

  xdg.configFile."qt6ct/qt6ct.conf".text = ''
    [Appearance]
    color_scheme_path=${config.home.homeDirectory}/.config/qt6ct/colors/noctalia.conf
    custom_palette=true
    style=Fusion
  '';

  xdg.dataFile."applications/tutanota-desktop.desktop".source =
    "${tutanotaDesktopEntry}/share/applications/tutanota-desktop.desktop";

  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/http" = [ "firefox.desktop" ];
    "x-scheme-handler/https" = [ "firefox.desktop" ];
    "text/html" = [ "firefox.desktop" ];
    "application/xhtml+xml" = [ "firefox.desktop" ];
    "application/x-extension-htm" = [ "firefox.desktop" ];
    "application/x-extension-html" = [ "firefox.desktop" ];
    "application/x-extension-shtml" = [ "firefox.desktop" ];
    "application/x-extension-xhtml" = [ "firefox.desktop" ];
    "application/x-extension-xht" = [ "firefox.desktop" ];
    "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
    "application/pdf" = [ "org.kde.okular.desktop" ];
    "image/png" = [ "org.kde.okular.desktop" ];
    "image/jpeg" = [ "org.kde.okular.desktop" ];
    "image/gif" = [ "org.kde.okular.desktop" ];
    "image/webp" = [ "org.kde.okular.desktop" ];
    "video/mp4" = [ "mpv.desktop" ];
    "video/x-matroska" = [ "mpv.desktop" ];
    "video/webm" = [ "mpv.desktop" ];
    "audio/mpeg" = [ "mpv.desktop" ];
    "audio/flac" = [ "mpv.desktop" ];
  };
}
