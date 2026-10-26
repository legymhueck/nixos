{ config, lib, ... }:

let
  cfg = config.nixbox.cursor;
in
{
  # Cursor theme and size, set in ./configuration.nix. Exported to the session
  # here and read back by Home Manager (./desktop.nix) via osConfig.
  options.nixbox.cursor = {
    theme = lib.mkOption {
      type = lib.types.str;
      description = "Cursor theme name (installed in ./packages.nix).";
    };
    size = lib.mkOption {
      type = lib.types.ints.positive;
      description = "Cursor size in pixels.";
    };
  };

  config.environment.sessionVariables = {
    XCURSOR_THEME = cfg.theme;
    XCURSOR_SIZE = toString cfg.size;
    XCURSOR_PATH = [ "/run/current-system/sw/share/icons" ];
  };
}
