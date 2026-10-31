{
  lib,
  pkgs,
  osConfig,
  ...
}:

{
  # Large nixpkgs applications, active from the apps stage on. Local packages
  # and customized builds are in ./built.nix.
  config = lib.mkIf (osConfig.nixbox.stage != "base") {
    home.packages = with pkgs; [
      aria2
      aspell
      aspellDicts.de
      aspellDicts.en
      audacity
      blanket
      btrfs-assistant
      cava
      celluloid
      cmatrix
      conjure
      duckdb
      dvdbackup
      filen-desktop
      filius
      gimp
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
      iperf3
      # Java 21 with JavaFX built in, like Liberica JDK Full on the school PCs
      # (cached on cache.nixos.org, no local build).
      (jdk21.override { enableJavaFX = true; })
      khal
      kdePackages.kdenlive
      kdePackages.partitionmanager
      libreoffice
      lite-xl
      localsend
      logisim-evolution
      meld
      mistral-rs
      nuspell
      onlyoffice-desktopeditors
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
