{
  lib,
  pkgs,
  inputs,
  vars,
  ...
}:
{
  # The generated hardware-configuration.nix is added by the flake.
  imports = [
    inputs.mango.nixosModules.mango
    ../common/base.nix
    ../common/hardware-intel-laptop.nix
    ./cursor.nix
    ./packages.nix
  ];

  # Mango specific: the Noctalia binary cache (avoids compiling the shell).
  nix.settings = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  # nixbox.batteryThresholds = { start = 70; end = 80; };

  # --- desktop ---
  programs.mango.enable = true; # session entry, portals, polkit, Xwayland
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
  };
  # Single source for the cursor; Home Manager (desktop.nix) reads it back.
  nixbox.cursor = {
    theme = "Breeze_Hacked";
    size = 48;
  };
  environment.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt6ct";
    GTK_THEME = "adw-gtk3-dark"; # adw-gtk3 is installed in ./packages.nix
    SAL_USE_VCLPLUGIN = "gtk3"; # LibreOffice
  };

  # --- login: one password, no login screen at boot ---
  # 1. You type the disk (LUKS) passphrase at boot.
  # 2. greetd logs the user in automatically (initial_session, boot only) and
  #    starts Mango.
  # 3. The same passphrase is handed to gnome-keyring (pam_fde_boot_pw), so the
  #    keyring (Brave, Bitwarden, ...) is unlocked without a second prompt.
  # 4. The Noctalia lock screen uses the same password as the account.
  # Therefore: the LUKS passphrase and the password of the user must stay
  # identical (see README, "Changing the password").
  # After a logout or compositor crash greetd shows tuigreet and asks for the
  # password: an autologin there would hand an unlocked session to anyone who
  # can crash the compositor of a locked laptop.
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "mango";
        inherit (vars) user;
      };
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd mango";
        user = "greeter";
      };
    };
  };
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    KeyringMode = lib.mkForce "inherit";
  };
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  services.gnome.gnome-keyring.enable = true; # Secret Service (Brave, Bitwarden, ...)
  # greetd includes login, which would otherwise start gnome-keyring before the
  # LUKS key is injected. Handle it in greetd's own session stack instead.
  security.pam.services.login.enableGnomeKeyring = lib.mkForce false;
  security.pam.services.greetd.rules.session = {
    fde_boot_pw = {
      order = 12600;
      control = "optional";
      modulePath = "${pkgs.pam_fde_boot_pw}/lib/security/pam_fde_boot_pw.so";
      args = [ "inject_for=gkr" ];
    };
    gnome_keyring = {
      order = 12700;
      control = "optional";
      modulePath = "${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so";
      args = [ "auto_start" ];
    };
  };
}
