{
  description = "nixos workstation configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Pinned on purpose: HandBrake is taken from this revision instead of
    # nixos-unstable (see common/home-packages.nix). Review every few months;
    # drop this input and use pkgs.handbrake once unstable is fine again.
    nixpkgs-handbrake.url = "github:NixOS/nixpkgs/00c33702baa387c313bcfa919ef1c9565ec45c20";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mango = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hylki = {
      url = "path:./flakes/hylki";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    bibox = {
      url = "path:./flakes/bibox";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cornelsen_offline_lernen = {
      url = "path:./flakes/cornelsen_offline_lernen";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mtplayer = {
      url = "path:./flakes/mtplayer";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    doublecmd-qt6 = {
      url = "path:./flakes/doublecmd-qt6";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    revpdf = {
      url = "path:./flakes/revpdf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia";
    };
    noctalia_official_plugins = {
      url = "github:noctalia-dev/official-plugins";
      flake = false;
    };
    noctalia_community_plugins = {
      url = "github:noctalia-dev/community-plugins";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      mango,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;
      vars = import ./common/vars.nix;
      system = "x86_64-linux";
      variants = [
        "mango"
        "plasma"
      ];

      hardwareFile = variant: ./. + "/nixos-${variant}/hardware-configuration.nix";
      hasHardware = variant: builtins.pathExists (hardwareFile variant);

      # Only for the `-eval` outputs: lets a checkout without the generated
      # hardware module evaluate (CI, `nix flake check`). It is never part of
      # the real configurations, so a missing hardware module there fails
      # loudly instead of producing an unbootable system.
      evaluationHardware =
        { lib, ... }:
        {
          fileSystems = lib.genAttrs [ "/" "/home" "/nix" "/var/log" ] (_: {
            device = lib.mkDefault "/dev/null";
            fsType = lib.mkDefault "btrfs";
          });
          boot.initrd.luks.devices.cryptroot.device = lib.mkDefault "/dev/null";
        };

      # Install stage, read from ./stage: "base" (what install.sh installs from
      # the ISO: encrypted system, desktop, small package set) or "full" (adds
      # the large applications and local builds, switched on by post-install.sh).
      # Default is "full" so a checkout without the file behaves as before.
      fileStage =
        if builtins.pathExists ./stage then lib.removeSuffix "\n" (builtins.readFile ./stage) else "full";

      mkSystem =
        {
          variant,
          evalOnly ? false,
          stage ? fileStage,
        }:
        assert lib.assertMsg (lib.elem stage [
          "base"
          "full"
        ]) "./stage must contain 'base' or 'full', not '${stage}'";
        lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs stage; };
          modules = [
            (./. + "/nixos-${variant}/configuration.nix")
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "bak";
                extraSpecialArgs = { inherit inputs stage; };
                users.${vars.user} = import (./. + "/nixos-${variant}/home.nix");
              };
            }
          ]
          ++ lib.optional (variant == "mango") mango.nixosModules.mango
          ++ lib.optional evalOnly evaluationHardware;
        };

      # Which variant `nixos-rebuild --flake .` (hostname nixbox) builds. The
      # installer writes the chosen variant to ./profile; default is mango.
      profile =
        if builtins.pathExists ./profile then
          lib.removeSuffix "\n" (builtins.readFile ./profile)
        else
          "mango";

      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      formatter.${system} = pkgs.nixfmt-tree;

      nixosConfigurations =
        let
          named =
            suffix: variants': extra:
            map (variant: {
              name = "${vars.host}-${variant}${suffix}";
              value = mkSystem ({ inherit variant; } // extra);
            }) variants';
        in
        lib.listToAttrs (
          # Real configurations exist only where the generated hardware module
          # is present (the committed one belongs to the current machine).
          named "" (lib.filter hasHardware variants) { }
          # Evaluation-only twins for CI and `nix eval`; never deploy these.
          # Both stages are always checked, independent of ./stage.
          ++ named "-eval" variants {
            evalOnly = true;
            stage = "full";
          }
          ++ named "-base-eval" variants {
            evalOnly = true;
            stage = "base";
          }
        )
        # `nixos-rebuild --flake .` / `nh os switch` look up the hostname.
        // lib.optionalAttrs (hasHardware profile) {
          ${vars.host} = self.nixosConfigurations."${vars.host}-${profile}";
        };

      checks.${system}.lint =
        pkgs.runCommandLocal "lint"
          {
            nativeBuildInputs = with pkgs; [
              deadnix
              shellcheck
              statix
            ];
          }
          ''
            cd ${self}
            statix check .
            deadnix --fail --exclude "**/hardware-configuration.nix" .
            shellcheck install.sh install-heavy-apps.sh post-install.sh dotfiles/scripts/.local/share/scripts/*.sh
            touch $out
          '';
    };
}
