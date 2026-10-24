{ pkgs, ... }:

{
  # System-wide tools shared by both desktop variants.
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
    deadnix
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
    shellcheck
    shfmt
    smartmontools
    statix
    tpm2-tools
    traceroute
    usbutils
    vim
    vulkan-tools
    xdg-utils
  ];
}
