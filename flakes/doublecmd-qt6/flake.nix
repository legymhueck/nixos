{
  description = "Double Commander built with Qt 6";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      doublecmd-qt6 = pkgs.callPackage ./package.nix { };
    in
    {
      packages.${system} = {
        inherit doublecmd-qt6;
        default = doublecmd-qt6;
      };
    };
}
