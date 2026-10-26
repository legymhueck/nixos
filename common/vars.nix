# Single source for names used by the flake, NixOS and Home Manager modules
# (as the `vars` module argument), and by install.sh (read with
# nix-instantiate). Plain data: no arguments.
{
  user = "m";
  host = "nixbox";
  # Btrfs subvolume mount points (@, @home, @nix, @log, created by install.sh).
  btrfsMounts = [
    "/"
    "/home"
    "/nix"
    "/var/log"
  ];
}
