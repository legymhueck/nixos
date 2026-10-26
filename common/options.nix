{ lib, ... }:

{
  options.nixbox.stage = lib.mkOption {
    type = lib.types.enum [
      "base"
      "apps"
      "full"
    ];
    description = ''
      Install stage, set by the flake from ./stage. Home Manager reads it as
      osConfig.nixbox.stage: base = small package set (apps.nix and built.nix
      inactive), apps = plus the large cached applications (apps.nix),
      full = plus local packages and customized builds (built.nix).
    '';
  };
}
