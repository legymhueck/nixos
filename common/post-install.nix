{ pkgs, inputs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;

  # Pinned nixpkgs revision for HandBrake (see the nixpkgs-handbrake input in
  # flake.nix for when to drop it).
  unstableHandbrake = (import inputs.nixpkgs-handbrake { inherit system; }).handbrake;

in
{
  # Large nixpkgs applications for the optional apps stage. Local flakes and
  # unfree packages are installed separately by ./built-packages.nix.
  home.packages = with pkgs; [
    aria2
    aspell
    aspellDicts.de
    aspellDicts.en
    blanket
    btrfs-assistant
    cava
    celluloid
    cmatrix
    conjure
    dvdbackup
    gimp
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
    libreoffice
    localsend
    meld
    mistral-rs
    nuspell
    openconnect
    pandoc
    python3
    ruff
    scrcpy
    tinymist
    typst
    uv
    vlc
    vorta
    yt-dlp
  ];
}
