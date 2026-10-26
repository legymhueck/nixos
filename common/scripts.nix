{ pkgs, ... }:

let
  # ../scripts/<name>.sh becomes the command <name>, checked by shellcheck at
  # build time and with its dependencies on PATH.
  mkScript =
    name: runtimeInputs:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text = builtins.readFile (../scripts + "/${name}.sh");
    };
in
{
  home.packages = with pkgs; [
    (mkScript "format-and-mount" [
      btrfs-progs
      cryptsetup
      util-linux
    ])
    (mkScript "nfs-mount" [
      nfs-utils
      util-linux
    ])
    (mkScript "snapper-delete" [
      gawk
      snapper
    ])
    (mkScript "ssh-permissions" [ findutils ])
    (mkScript "to-webm" [ ffmpeg ])
    (mkScript "update-check" [
      curl
      git
      jq
    ])
  ];
}
