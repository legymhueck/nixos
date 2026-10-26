{
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  # nixpkgs installs only an XPM and sets Icon=veracrypt.xpm, which Noctalia
  # cannot resolve (https://github.com/NixOS/nixpkgs/issues/574140). Add the
  # upstream PNG/SVG icons from VeraCrypt's source and use the icon name.
  # Drop this wrapper once nixpkgs installs them.
  veracrypt = pkgs.symlinkJoin {
    name = "veracrypt-with-icons-${pkgs.veracrypt.version}";
    paths = [ pkgs.veracrypt ];
    postBuild = ''
      icons=${pkgs.veracrypt.src}/src/Resources/Icons
      hicolor="$out/share/icons/hicolor"
      for size in 16 22 24 32 48 64 128 256 512 1024; do
        install -Dm444 "$icons/VeraCrypt-''${size}x''${size}.png" \
          "$hicolor/''${size}x''${size}/apps/veracrypt.png"
      done
      install -Dm444 "$icons/VeraCrypt.svg" "$hicolor/scalable/apps/veracrypt.svg"
      install -Dm444 "$icons/VeraCrypt-symbolic.svg" "$hicolor/symbolic/apps/veracrypt-symbolic.svg"

      desktop="$out/share/applications/veracrypt.desktop"
      cp --remove-destination "$(readlink -f "$desktop")" "$desktop"
      chmod u+w "$desktop"
      sed -i 's|^Icon=.*|Icon=veracrypt|' "$desktop"
    '';
  };
in
{
  # Local packages (../pkgs), customized builds, and unfree applications not
  # required by the base desktop, active in the full stage. Brave remains in the
  # base set because it is a core browser.
  config = lib.mkIf (osConfig.nixbox.stage == "full") {
    home.packages =
      (with pkgs; [
        antigravity-ide
        bibox
        chatgpt
        claude-code
        cornelsen-offline-lernen
        github-copilot-cli
        hylki
        megasync
        mtplayer
        obsidian
        opencode
        pi-coding-agent
        proton-authenticator
        revpdf
        signal-desktop
        xnviewmp
        zed-editor
      ])
      ++ [ veracrypt ];

    programs.vscode = {
      enable = true;
      package = pkgs.vscode;
      profiles.default.extensions = with pkgs.vscode-extensions; [
        anthropic.claude-code
        bbenoist.nix
        davidanson.vscode-markdownlint
        donjayamanne.githistory
        github.vscode-github-actions
        github.vscode-pull-request-github
        marp-team.marp-vscode
        ms-python.debugpy
        ms-python.python
        ms-python.vscode-pylance
        ms-python.vscode-python-envs
        ms-vscode.powershell
        myriad-dreamin.tinymist
        oracle.oracle-java
        redhat.java
        tomoki1207.pdf
        vscjava.vscode-java-debug
        vscjava.vscode-java-dependency
        vscjava.vscode-java-pack
        vscjava.vscode-java-test
        yzane.markdown-pdf
        yzhang.markdown-all-in-one
      ];
    };

    xdg.mimeApps.defaultApplications."x-scheme-handler/mailto" = [ "co.hyprlab.Hylki.desktop" ];
  };
}
