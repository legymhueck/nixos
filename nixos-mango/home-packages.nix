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
          hash = lib.fakeHash; # build once, then paste the hash from the error
        }
      }/pCloud.AppImage";
    };

    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];

    # The Electron/AppImage app does not pick up the cursor from the session.
    postFixup = (old.postFixup or "") + ''
      wrapProgram $out/bin/pcloud \
        --set XCURSOR_THEME ${sv.XCURSOR_THEME} \
        --set XCURSOR_SIZE ${sv.XCURSOR_SIZE} \
        --set XCURSOR_PATH ${lib.concatStringsSep ":" (lib.toList sv.XCURSOR_PATH)}
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
