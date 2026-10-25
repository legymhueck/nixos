{
  pkgs,
  inputs,
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
  # Mango-only post-install user packages (large applications, local builds).
  # Imported by ./home.nix only when the stage is "full" (see post-install.sh).
  # The shared ones are in ../common/post-install.nix.
  home.packages =
    (with pkgs; [
      bitwarden-desktop
      flameshot
      gpu-screen-recorder
      intellij-idea
      kdePackages.kdeconnect-kde
      pcloud
      proton-pass
      pycharm
      qview
      tutanota-desktop
      whatsie
    ])
    ++ [
      inputs.doublecmd-qt6.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

  xdg.dataFile."applications/tutanota-desktop.desktop".source =
    "${tutanotaDesktopEntry}/share/applications/tutanota-desktop.desktop";

  # xnviewmp (common/post-install.nix) does not provide a desktop entry itself.
  xdg.desktopEntries.xnviewmp = {
    name = "XnView MP";
    genericName = "Image Viewer";
    comment = "View and organize images";
    exec = "xnviewmp %F";
    icon = "image-x-generic";
    categories = [
      "Graphics"
      "Viewer"
    ];
    terminal = false;
  };
}
