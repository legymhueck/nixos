{ pkgs, inputs, ... }:

{
  home.packages =
    (with pkgs; [
      bitwarden-desktop
      intellij-idea
      pcloud
      proton-pass
      pycharm
    ])
    ++ [
      inputs.doublecmd-qt6.packages.${pkgs.stdenv.hostPlatform.system}.default
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
}
