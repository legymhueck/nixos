{
  pkgs,
  inputs,
  lib,
  osConfig,
  ...
}:

let
  # Single source for the cursor: nixos-mango/configuration.nix
  sv = osConfig.environment.sessionVariables;

  pcloudVersion = "2.3.1";

  # nixpkgs' pcloud (a repacked AppImage, nothing is compiled) with a newer
  # version and the system cursor. Once nixpkgs ships 2.3.1, drop `version` and
  # `src` and keep only the wrapper.
  pcloud = pkgs.pcloud.overrideAttrs (old: {
    version = pcloudVersion;

    src = pkgs.appimageTools.extract {
      pname = "pcloud";
      version = pcloudVersion;
      src = "${
        pkgs.fetchzip {
          # Code of the release: https://www.pcloud.com/release-notes/linux.html
          url = "https://api.pcloud.com/getpubzip?code=XZtJmbJZp6YyRQOCSjbAwPVct6fTXJloyHhy&filename=pcloud-${pcloudVersion}.zip";
          hash = "sha256-MrEuAwKsGXHwTr7garKLN0OQYkqRji/RxN/DACKcLa0=";
        }
      }/pCloud.AppImage";
    };

    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];

    # The package is a plain extracted AppImage, so NIXOS_OZONE_WL is ignored
    # and Electron would run under XWayland, where the cursor comes from the X
    # client (not from Mango's cursor_theme). Force native Wayland (env var, so
    # it works even if the launcher script drops arguments) and make GSettings
    # (cursor-theme from desktop.nix) and the dconf backend visible, because
    # Chromium asks GTK for the theme before it looks at XCURSOR_*.
    postFixup = (old.postFixup or "") + ''
      wrapProgram $out/bin/pcloud \
        --set ELECTRON_OZONE_PLATFORM_HINT auto \
        --prefix XDG_DATA_DIRS : ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name} \
        --prefix GIO_EXTRA_MODULES : ${pkgs.dconf.lib}/lib/gio/modules \
        --set XCURSOR_THEME ${sv.XCURSOR_THEME} \
        --set XCURSOR_SIZE ${sv.XCURSOR_SIZE} \
        --set XCURSOR_PATH ${lib.concatStringsSep ":" (lib.toList sv.XCURSOR_PATH)}
      substituteInPlace $out/share/applications/pcloud.desktop \
        --replace-fail 'Exec=pcloud' "Exec=$out/bin/pcloud"
    '';
  });
in
{
  # Mango-only user packages (the shared set is in ../common/home-packages.nix).
  home.packages = [
    (import ../common/brave.nix {
      inherit pkgs;
      passwordStore = "gnome-libsecret";
    })
    pcloud
  ]
  ++ (with pkgs; [
    adwaita-icon-theme
    bitwarden-desktop
    flameshot
    gpu-screen-recorder
    intellij-idea
    kdePackages.kdeconnect-kde
    nautilus
    proton-pass
    pycharm
    qview
    trash-cli
    tutanota-desktop
    udiskie
    whatsie
  ])
  ++ [
    inputs.doublecmd-qt6.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
