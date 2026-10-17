{ pkgs, inputs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;

  # MyPaint 2.0.1 (nixos-26.05) predates PyGObject 3.51 compatibility.
  mypaint = pkgs.stable.mypaint.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace lib/glib.py --replace-fail "k.value_name" "k.name"
    '';
  });

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
  # User packages shared by the Mango and Plasma variants. Desktop-specific
  # ones are in nixos-<variant>/home-packages.nix. starship, zoxide, eza and
  # the GitHub CLI come from programs.* in common/home.nix.
  home.packages =
    (with pkgs; [
      antigravity-ide
      aria2
      aspell
      aspellDicts.de
      aspellDicts.en
      audacity
      bat
      blanket
      btop
      btrfs-assistant
      cava
      celluloid
      cmatrix
      conjure
      dvdbackup
      fd
      fira-code
      fzf
      gimp
      github-copilot-cli
      gst_all_1.gst-libav
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-ugly
      handbrake
      helix
      hunspell
      hunspellDicts.de_DE
      hunspellDicts.en_GB-large
      hunspellDicts.en_US
      hyphen
      hyphenDicts.de_DE
      hyphenDicts.en_GB
      hyphenDicts.en_US
      inter
      iperf3
      jdk
      kdePackages.breeze-icons
      kdePackages.kdenlive
      kdePackages.kimageformats
      kdePackages.okular
      kdePackages.partitionmanager
      khal
      kitty
      less
      liberation_ttf
      libreoffice
      lsof
      meld
      micro
      mpv
      nuspell
      obsidian
      opencode
      openconnect
      p7zip
      pandoc
      proton-authenticator
      pwvucontrol
      python3
      qt6Packages.qt6ct
      ripgrep
      rsync
      ruff
      scrcpy
      sshfs
      tealdeer
      tinymist
      typst
      unzip
      uv
      vlc
      vorta
      vscode
      wget
      which
      wl-clipboard
      yt-dlp
      zed-editor
      zip
    ])
    ++ [
      mypaint
      veracrypt
      pkgs.stable.filen-desktop
      inputs.hylki.packages.${system}.default
      inputs.bibox.packages.${system}.default
      inputs.cornelsen_offline_lernen.packages.${system}.default
      inputs.mtplayer.packages.${system}.default
    ];
}
