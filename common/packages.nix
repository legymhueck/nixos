{ pkgs, ... }:

{
  # System-wide tools shared by both desktop variants. Linters and formatters
  # for this repository are in the dev shell (`nix develop`).
  environment.systemPackages = with pkgs; [
    acpi
    alsa-utils
    asciidoc
    asciidoctor
    bash-completion
    bind
    brightnessctl
    btrfs-progs
    compsize
    ddcutil
    dosfstools
    exfatprogs
    ffmpeg
    git
    i2c-tools
    jq
    man-db
    man-pages
    mc
    nfs-utils
    ntfs3g
    openssh
    rclone
    smartmontools
    tpm2-tools
    traceroute
    usbutils
    vim
    vulkan-tools
    xdg-utils
  ];
}
