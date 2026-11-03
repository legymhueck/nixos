{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

{
  # Large nixpkgs applications, active from the apps stage on. Local packages
  # and customized builds are in ./built.nix.
  config = lib.mkIf (osConfig.nixbox.stage != "base") {
    # Double Commander reads the extension -> icon name mapping only from
    # /usr/share/mime and ~/.local/share/mime (hardcoded in
    # src/platform/upixmapmanager.pas), so without these files it shows no
    # file type icons. Link them from Home Manager's MIME database.
    xdg.dataFile = lib.genAttrs [ "mime/globs" "mime/icons" "mime/generic-icons" ] (f: {
      source = "${config.home.path}/share/${f}";
    });

    home.packages = with pkgs; [
      aria2
      aspell
      aspellDicts.de
      aspellDicts.en
      audacity
      blanket
      btrfs-assistant
      cargo
      cava
      celluloid
      cmatrix
      conjure
      duckdb
      dvdbackup
      # nixpkgs' cached Qt5 build is themed through Noctalia via qt5ct;
      # configuration is in ../dotfiles/doublecmd, MIME data below.
      doublecmd
      filen-desktop
      filius
      gimp
      gcc
      greenfoot
      gst_all_1.gst-libav
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-ugly
      hunspell
      hunspellDicts.de_DE
      hunspellDicts.en_GB-large
      hunspellDicts.en_US
      hyphen
      hyphenDicts.de_DE
      hyphenDicts.en_GB
      hyphenDicts.en_US
      # Keep the Conjure image editor above; ImageMagick ships an unrelated
      # `conjure` executable with the same path.
      (symlinkJoin {
        name = "imagemagick-without-conjure";
        paths = [ imagemagick ];
        postBuild = "rm $out/bin/conjure";
      })
      iperf3
      # Java 21 with JavaFX built in, like Liberica JDK Full on the school PCs
      # (cached on cache.nixos.org, no local build).
      (jdk21.override { enableJavaFX = true; })
      khal
      kdePackages.kdenlive
      kdePackages.partitionmanager
      libavif
      libreoffice
      lite-xl
      localsend
      logisim-evolution
      meld
      mistral-rs
      nuspell
      openconnect
      pandoc
      plantuml
      (python3.withPackages (
        ps: with ps; [
          duckdb
          pillow
          pymupdf
          pdftotext
        ]
      ))
      rnote
      ruff
      rustc
      scrcpy
      tinymist
      typst
      uv
      vlc
      vorta
      yed
      yt-dlp
    ];
  };
}
