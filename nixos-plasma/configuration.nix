{
  # The generated hardware-configuration.nix is added by the flake.
  imports = [
    ../common/base.nix
    ../common/hardware-intel-laptop.nix
  ];

  services.xserver.xkb.layout = "de"; # keyboard layout for SDDM and Plasma (Wayland)

  # --- desktop: KDE Plasma 6 (Wayland) with SDDM ---
  # SDDM asks for the account password; KWallet is unlocked with it. (Autologin
  # would leave KWallet locked, so it is not enabled here.)
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  programs.kdeconnect.enable = true; # package plus firewall ports
}
