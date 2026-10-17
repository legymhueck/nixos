{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.nixbox;
  batteryPath = "/sys/class/power_supply/BAT0";

  # Brave managed policies (Brave reads /etc/brave/policies/managed, NOT the
  # /etc/chromium path that programs.chromium writes).
  bravePolicies = {
    # blank page on launch and for every new tab
    NewTabPageLocation = "about:blank";
    HomepageLocation = "about:blank";
    HomepageIsNewTabPage = false;
    RestoreOnStartup = 5; # 5 = open the New Tab page (= about:blank)

    # start-page content / built-in extras
    BraveRewardsDisabled = true;
    BraveWalletDisabled = true;
    BraveVPNDisabled = true;
    BraveTalkDisabled = true;
    BraveNewsDisabled = true;
    BraveAIChatEnabled = false;
    BravePlaylistEnabled = false;
    BraveSpeedreaderEnabled = false;
    BraveWaybackMachineEnabled = false;

    # telemetry / stats
    BraveP3AEnabled = false;
    BraveStatsPingEnabled = false;
    BraveWebDiscoveryEnabled = false;
    MetricsReportingEnabled = false;

    # miscellaneous prompts
    PromotionalTabsEnabled = false;
    DefaultBrowserSettingEnabled = false;
    BrowserSignin = 0;
  };
in
{
  imports = [ ./packages.nix ];

  # Base system shared by the Mango and Plasma variants (hardware: Intel laptop,
  # UEFI, LUKS2 + Btrfs). Desktop-specific parts live in nixos-<variant>/.

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
    # --- nix: pinned, reproducible, self-cleaning ---
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    # `nix shell nixpkgs#foo` and <nixpkgs> use the same revision as the system.
    nix.registry.nixpkgs.flake = inputs.nixpkgs;
    nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
    nix.optimise.automatic = true; # dedupe the store
    nixpkgs.config.allowUnfree = true; # drop if you want free software only
    # pkgs.stable: the nixos-26.05 package set (for packages broken on unstable).
    # Also visible to Home Manager because of home-manager.useGlobalPkgs.
    nixpkgs.overlays = [
      (final: _prev: {
        stable = import inputs.nixpkgs-stable {
          inherit (final.stdenv.hostPlatform) system;
          config.allowUnfree = true;
        };
      })
    ];
    # nh: nicer rebuilds (`nh os switch`) and the weekly garbage collection
    # (replaces nix.gc, they must not both be enabled).
    programs.nh = {
      enable = true;
      flake = "/home/m/nixos";
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep-since 14d --keep 5";
      };
    };

    # --- boot, LUKS, Btrfs, zram ---
    boot.loader.systemd-boot = {
      enable = true;
      editor = false; # no kernel-parameter editing from the boot menu
      configurationLimit = 10;
    };
    boot.loader.timeout = 3;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.initrd.systemd.enable = true; # needed: passes the passphrase to the session
    boot.initrd.luks.devices.cryptroot = {
      # merged with the generated entry
      allowDiscards = true; # TRIM through LUKS (leaks which blocks are free)
      bypassWorkqueues = true; # faster on NVMe
    };

    fileSystems = lib.mkMerge [
      (lib.genAttrs [ "/" "/home" "/nix" "/var/log" ] (_: {
        options = [
          "compress=zstd"
          "noatime"
        ];
      })) # merged with generated subvol=
      { "/var/log".neededForBoot = true; }
    ];
    services.btrfs.autoScrub.enable = true;
    services.fstrim.enable = true;

    # No swap file: zram is enough on this machine and keeps snapshots simple.
    # (The installer only uses a temporary swap file while it builds.)
    # No hibernation without disk swap.
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 50;
    };
    boot.kernel.sysctl = {
      "vm.swappiness" = 180;
      "vm.page-cluster" = 0;
    }; # zram tuning

    # --- basics: English UI, German formats ---
    networking.hostName = "nixbox";
    networking.networkmanager.enable = true;
    time.timeZone = "Europe/Berlin";
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = lib.genAttrs [
      "LC_ADDRESS"
      "LC_IDENTIFICATION"
      "LC_MEASUREMENT"
      "LC_MONETARY"
      "LC_NAME"
      "LC_NUMERIC"
      "LC_PAPER"
      "LC_TELEPHONE"
      "LC_TIME"
    ] (_: "de_DE.UTF-8");
    console.keyMap = "de-latin1";
    console.earlySetup = true; # German layout already at the LUKS passphrase prompt

    users.users.m = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        "video"
        "audio"
        "i2c"
      ];
    };
    # Root login is disabled; use sudo from user "m" (wheel).
    users.users.root.hashedPassword = "!";

    # --- snapshots: /home, hourly/daily/weekly/monthly ---
    services.snapper.configs.home = {
      SUBVOLUME = "/home";
      ALLOW_USERS = [ "m" ];
      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;
      TIMELINE_LIMIT_HOURLY = 5;
      TIMELINE_LIMIT_DAILY = 7;
      TIMELINE_LIMIT_WEEKLY = 4;
      TIMELINE_LIMIT_MONTHLY = 3;
      TIMELINE_LIMIT_YEARLY = 0;
    };
    # "v" creates a btrfs subvolume if it does not exist yet
    systemd.tmpfiles.rules = [ "v /home/.snapshots 0700 root root -" ];

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

    # --- services ---
    services.printing.enable = true;
    services.fprintd.enable = true;
    services.fwupd.enable = true;
    services.hardware.bolt.enable = true;
    services.udisks2.enable = true;
    services.avahi = {
      enable = true;
      nssmdns4 = true;
    };
    # Workaround: a stale PID file stops avahi after a crash or hard power-off.
    systemd.services.avahi-daemon.serviceConfig.ExecStartPre = [
      "+${pkgs.coreutils}/bin/rm -f /run/avahi-daemon/pid"
    ];
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client"; # exit nodes / subnet routes
    };
    networking.firewall.checkReversePath = "loose"; # needed for Tailscale exit nodes
    hardware.i2c.enable = true; # ddcutil: i2c-dev module + "i2c" group
    hardware.firmware = [ pkgs.sof-firmware ];

    # --- desktop plumbing shared by both variants ---
    programs.dconf.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
    security.rtkit.enable = true;
    hardware.bluetooth.enable = true;
    services.power-profiles-daemon.enable = true;
    services.thermald.enable = true; # Intel thermal management
    services.upower.enable = true;
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1"; # Electron/Chromium on Wayland
      LIBVA_DRIVER_NAME = "iHD"; # intel-media-driver
    };
    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono
      carlito
    ];
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vpl-gpu-rt # QSV on Gen12+ (Tiger Lake and newer)
      ];
    };

    # --- Brave: strip the start page, telemetry and extra features ---
    # Policies land in /etc/brave/policies/managed (see brave://policy).
    environment.etc."brave/policies/managed/brave.json".text = builtins.toJSON bravePolicies;
  };
}
