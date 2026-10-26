{
  description = "nixos workstation configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mango = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # No nixpkgs.follows: the Noctalia Cachix cache only matches its own pin.
    noctalia.url = "github:noctalia-dev/noctalia";
    noctalia_official_plugins = {
      url = "github:noctalia-dev/official-plugins";
      flake = false;
    };
    noctalia_community_plugins = {
      url = "github:noctalia-dev/community-plugins";
      flake = false;
    };

    # Sources of local packages in ./pkgs. Update with: nix flake update hylki-src
    hylki-src = {
      url = "github:hyprlab/hylki";
      flake = false;
    };
    revpdf-release = {
      url = "github:Pawandeep-prog/revpdf-release/dd72f556be18d7a87b301a82ee33397aeb2ced32";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;
      vars = import ./common/vars.nix;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      variants = [
        "mango"
        "plasma"
      ];

      hardwareFile = variant: ./. + "/nixos-${variant}/hardware-configuration.nix";
      hasHardware = variant: builtins.pathExists (hardwareFile variant);

      # Only for the `-eval` outputs: stands in for the generated hardware
      # module so a checkout without it evaluates (CI, `nix flake check`). It is
      # never part of the real configurations, so a missing hardware module
      # there fails loudly instead of producing an unbootable system.
      evaluationHardware = {
        fileSystems = lib.genAttrs vars.btrfsMounts (_: {
          device = "/dev/null";
          fsType = "btrfs";
        });
        boot.initrd.luks.devices.cryptroot.device = "/dev/null";
      };

      readFileOr =
        file: default: if builtins.pathExists file then lib.trim (builtins.readFile file) else default;

      # Install stage (base, apps, full; written by the install scripts). The
      # committed stage and the default remain "full" for normal rebuilds.
      # Checked by the nixbox.stage option type.
      fileStage = readFileOr ./stage "full";

      # Which variant the hostname alias (`nh os switch`) builds. The installer
      # writes the chosen variant to ./profile; default is mango.
      profile = readFileOr ./profile "mango";

      mkSystem =
        {
          variant,
          evalOnly ? false,
          stage ? fileStage,
        }:
        lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs vars; };
          modules = [
            (./. + "/nixos-${variant}/configuration.nix")
            (if evalOnly then evaluationHardware else hardwareFile variant)
            { nixbox.stage = stage; }
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "bak";
                extraSpecialArgs = { inherit inputs vars; };
                users.${vars.user} = ./. + "/nixos-${variant}/home.nix";
              };
            }
          ];
        };

      # Names of the local packages from ./pkgs (the overlay is not evaluated).
      localPackages = builtins.attrNames (import ./pkgs { inherit inputs; } { } { });
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
          # All install stages are checked, independent of ./stage.
          ++ named "-eval" variants {
            evalOnly = true;
            stage = "full";
          }
          ++ named "-apps-eval" variants {
            evalOnly = true;
            stage = "apps";
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

      # Local packages built with the system's package set (overlays, unfree
      # allowlist), e.g. `nix build .#hylki`.
      packages.${system} =
        let
          systemPkgs = self.nixosConfigurations."${vars.host}-mango-eval".pkgs;
        in
        lib.genAttrs localPackages (name: systemPkgs.${name});

      # Tools for working on this repository: `nix develop`.
      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = with pkgs; [
          deadnix
          nixfmt
          shellcheck
          shfmt
          statix
        ];
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
            shellcheck install.sh install-stage.sh scripts/*.sh pkgs/*/*.sh
            touch $out
          '';
    };
}
