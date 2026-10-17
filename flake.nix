{
  description = "nixos workstation configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
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
      evaluationHardware = hardwareConfiguration: { lib, ... }: {
        # Let a clean checkout evaluate; installed targets supply this from the
        # generated hardware module instead.
        fileSystems = lib.mkIf (!builtins.pathExists hardwareConfiguration) (
          lib.genAttrs [ "/" "/home" "/nix" "/var/log" ] (_: {
            device = "/dev/null";
            fsType = "btrfs";
          })
        );
        boot.initrd.luks.devices.cryptroot.device = lib.mkIf (
          !builtins.pathExists hardwareConfiguration
        ) "/dev/null";
      };

      # Which variant `nixos-rebuild --flake .` (hostname nixbox) builds. The
      # installer writes the chosen variant to ./profile; default is mango.
      profile =
        if builtins.pathExists ./profile then
          nixpkgs.lib.removeSuffix "\n" (builtins.readFile ./profile)
        else
          "mango";
    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;

      nixosConfigurations = {
        # `nixos-rebuild --flake .` / `nh os switch` look up the hostname (nixbox).
        nixbox = self.nixosConfigurations."nixbox-${profile}";

        nixbox-mango = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            (evaluationHardware ./nixos-mango/hardware-configuration.nix)
            ./nixos-mango/configuration.nix
            mango.nixosModules.mango
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "bak";
                extraSpecialArgs = { inherit inputs; };
                users.m = import ./nixos-mango/home.nix;
              };
            }
          ];
        };

        nixbox-plasma = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            (evaluationHardware ./nixos-plasma/hardware-configuration.nix)
            ./nixos-plasma/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "bak";
                extraSpecialArgs = { inherit inputs; };
                users.m = import ./nixos-plasma/home.nix;
              };
            }
          ];
        };
      };
    };
}
