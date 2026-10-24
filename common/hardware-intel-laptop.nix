{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixbox;
  batteryPath = "/sys/class/power_supply/BAT0";
in
{
  # Hardware-specific part for an Intel (Tiger Lake or newer) ThinkPad-style
  # laptop. Imported by the variant configurations; leave it out (or replace it)
  # for a different machine. Shared system settings live in base.nix.

  options.nixbox.batteryThresholds = lib.mkOption {
    type = lib.types.nullOr (
      lib.types.submodule {
        options = {
          start = lib.mkOption { type = lib.types.int; };
          end = lib.mkOption { type = lib.types.int; };
        };
      }
    );
    default = null;
    example = {
      start = 70;
      end = 80;
    };
    description = "Battery charge limits (ThinkPad-style sysfs files). null leaves the firmware default.";
  };

  config = {
    # --- battery charge thresholds (opt-in: nixbox.batteryThresholds) ---
    systemd.services.battery-charge-threshold = lib.mkIf (cfg.batteryThresholds != null) {
      description = "Set battery charge thresholds";
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      serviceConfig.RemainAfterExit = true;
      script = ''
        if [ -w ${batteryPath}/charge_control_start_threshold ]; then
          echo ${toString cfg.batteryThresholds.start} > ${batteryPath}/charge_control_start_threshold
        fi
        if [ -w ${batteryPath}/charge_control_end_threshold ]; then
          echo ${toString cfg.batteryThresholds.end} > ${batteryPath}/charge_control_end_threshold
        fi
      '';
    };

    services.fprintd.enable = true;
    services.thermald.enable = true; # Intel thermal management
    hardware.firmware = [ pkgs.sof-firmware ];

    environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD"; # intel-media-driver
    hardware.graphics.extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt # QSV on Gen12+ (Tiger Lake and newer)
    ];

    environment.systemPackages = [ pkgs.intel-gpu-tools ];
  };
}
