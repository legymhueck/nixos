{ pkgs, inputs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;

  # khal 0.14.1 does not produce a manpage, despite nixpkgs declaring a `man`
  # output for it. Omit only that broken optional documentation output.
  khal = pkgs.khal.overrideAttrs {
    outputs = [
      "out"
      "doc"
      "dist"
    ];
    sphinxBuilders = [ "html" ];
  };

  # MyPaint 2.0.1 (nixos-26.05) predates PyGObject 3.51 compatibility.
  mypaint = pkgs.stable.mypaint.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace lib/glib.py --replace-fail "k.value_name" "k.name"
    '';
  });

  # Audacity 4.0.0 currently fails to compile against the unstable Qt stack.
  audacity = pkgs.stable.audacity;

  # Noctalia resolves PNG/SVG icons, while nixpkgs provides VeraCrypt's XPM.
  veracrypt = pkgs.symlinkJoin {
    name = "veracrypt-with-icon-${pkgs.veracrypt.version}";
    paths = [ pkgs.veracrypt ];
    nativeBuildInputs = [ pkgs.imagemagick ];
    postBuild = ''
      desktop="$out/share/applications/veracrypt.desktop"
      cp --remove-destination "$(readlink -f "$desktop")" "$desktop"
      chmod u+w "$desktop"
      sed -i 's|^Icon=.*|Icon=veracrypt|' "$desktop"
      xpm="$(find ${pkgs.veracrypt}/share -name 'veracrypt.xpm' | head -n 1)"
      mkdir -p "$out/share/icons/hicolor/256x256/apps"
      magick "$xpm" "$out/share/icons/hicolor/256x256/apps/veracrypt.png"
    '';
  };
in
{
  # Local flakes, customized builds, and unfree applications not required by
  # the base desktop. Brave remains in the base set because it is a core browser.
  home.packages =
    (with pkgs; [
      antigravity-ide
      chatgpt
      claude-code
      github-copilot-cli
      megasync
      obsidian
      opencode
      pi-coding-agent
      proton-authenticator
      signal-desktop
      veracrypt
      vscode
      xnviewmp
      zed-editor
      khal
    ])
    ++ [
      inputs.revpdf.packages.${system}.default
      mypaint
      audacity
      pkgs.stable.filen-desktop
      inputs.hylki.packages.${system}.default
      inputs.bibox.packages.${system}.default
      inputs.cornelsen_offline_lernen.packages.${system}.default
      inputs.mtplayer.packages.${system}.default
    ];

  xdg.mimeApps.defaultApplications."x-scheme-handler/mailto" = [ "co.hyprlab.Hylki.desktop" ];
}
