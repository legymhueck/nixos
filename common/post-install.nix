{ pkgs, inputs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;

  # Pinned nixpkgs revision for HandBrake (see the nixpkgs-handbrake input in
  # flake.nix for when to drop it).
  unstableHandbrake = (import inputs.nixpkgs-handbrake { inherit system; }).handbrake;

  # MyPaint 2.0.1 (nixos-26.05) predates PyGObject 3.51 compatibility.
  mypaint = pkgs.stable.mypaint.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace lib/glib.py --replace-fail "k.value_name" "k.name"
    '';
  });

  # Audacity 4.0.0 currently fails to compile against the unstable Qt stack.
  audacity = pkgs.stable.audacity;

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

  # nixpkgs only ships a 256x256 .xpm and points the desktop entry at
  # "veracrypt.xpm". Noctalia's icon resolver only handles .svg/.png, so the
  # icon never resolves. Instead of overriding the VeraCrypt build (which would
  # recompile it), wrap the finished package: convert the xpm to a PNG in
  # hicolor and patch the desktop entry. No rebuild of VeraCrypt itself.
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
  # Post-install user packages shared by the Mango and Plasma variants: the
  # large applications and everything that is built locally (VeraCrypt, the
  # package flakes in flakes/, patched packages). Imported by common/home.nix
  # only when the stage is "full" (see post-install.sh). The small base set is
  # in ./home-packages.nix.
  home.packages =
    let
      baseApplications = with pkgs; [
        antigravity-ide
        aria2
        aspell
        aspellDicts.de
        aspellDicts.en
        blanket
        btrfs-assistant
        cava
        celluloid
        chatgpt
        # chatgpt-cli
        claude-code
        cmatrix
        conjure
        dvdbackup
        gimp
        github-copilot-cli
        gst_all_1.gst-libav
        gst_all_1.gst-plugins-bad
        gst_all_1.gst-plugins-good
        gst_all_1.gst-plugins-ugly
        unstableHandbrake
        hunspell
        hunspellDicts.de_DE
        hunspellDicts.en_GB-large
        hunspellDicts.en_US
        hyphen
        hyphenDicts.de_DE
        hyphenDicts.en_GB
        hyphenDicts.en_US
        iperf3
        jdk
        kdePackages.kdenlive
        kdePackages.partitionmanager
        khal
        libreoffice
        localsend
        megasync
        meld
        mistral-rs
        nuspell
        obsidian
        opencode
        openconnect
        pandoc
        pi-coding-agent
        proton-authenticator
        python3
        ruff
        scrcpy
        signal-desktop
        tinymist
        typst
        uv
        vlc
        vorta
        vscode
        xnviewmp
        yt-dlp
        zed-editor
      ];

      localPackages = [
        inputs.revpdf.packages.${system}.default
        mypaint
        audacity
        veracrypt
        pkgs.stable.filen-desktop
        inputs.hylki.packages.${system}.default
        inputs.bibox.packages.${system}.default
        inputs.cornelsen_offline_lernen.packages.${system}.default
        inputs.mtplayer.packages.${system}.default
      ];
    in
    baseApplications ++ localPackages;

  xdg.mimeApps.defaultApplications."x-scheme-handler/mailto" = [ "co.hyprlab.Hylki.desktop" ];
}
