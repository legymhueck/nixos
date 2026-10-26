{
  lib,
  pkgs,
  osConfig,
  ...
}:

{
  # Mango-only unfree apps and local packages, active in the full stage (the
  # shared set is in ../common/built.nix).
  config = lib.mkIf (osConfig.nixbox.stage == "full") {
    home.packages = with pkgs; [
      bitwarden-desktop
      doublecmd-qt6
      intellij-idea
      pcloud
      proton-pass
      pycharm
    ];

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
  };
}
