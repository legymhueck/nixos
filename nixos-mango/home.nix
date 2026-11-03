{ config, pkgs, ... }:

{
  imports = [
    ../common/home.nix
    ./desktop.nix
    ./home-packages.nix
    # Active only from their install stage on (osConfig.nixbox.stage).
    ./apps.nix
    ./built.nix
  ];

  # Double Commander from nixpkgs is the Qt5 build, so it needs qt5ct; the
  # Qt6 variant stays for future Qt6 apps. qt5ct's plugin also registers the
  # "qt6ct" key, so one QT_QPA_PLATFORMTHEME (set in ./configuration.nix)
  # covers both. The Noctalia Qt template writes both color files (enabled in
  # ./desktop.nix).
  home.packages = with pkgs; [
    libsForQt5.qt5ct
    qt6Packages.qt6ct
  ];
  xdg.configFile = {
    "qt5ct/qt5ct.conf".text = ''
      [Appearance]
      color_scheme_path=${config.home.homeDirectory}/.config/qt5ct/colors/noctalia.conf
      custom_palette=true
      style=Fusion
    '';
    "qt6ct/qt6ct.conf".text = ''
      [Appearance]
      color_scheme_path=${config.home.homeDirectory}/.config/qt6ct/colors/noctalia.conf
      custom_palette=true
      style=Fusion
    '';
  };

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
