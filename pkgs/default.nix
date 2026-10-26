# Local packages, added to pkgs by the overlay in common/base.nix and exposed
# as flake outputs (`nix build .#hylki`). Upstream sources that are not plain
# fetches are flake inputs (hylki-src, revpdf-release).
{ inputs }:
final: _prev: {
  bibox = final.callPackage ./bibox/package.nix { };
  cornelsen-offline-lernen = final.callPackage ./cornelsen-offline-lernen/package.nix { };
  doublecmd-qt6 = final.callPackage ./doublecmd-qt6/package.nix { };
  hylki = final.callPackage ./hylki/package.nix { src = inputs.hylki-src; };
  mtplayer = final.callPackage ./mtplayer/package.nix { };
  revpdf = final.callPackage ./revpdf/package.nix { inherit (inputs) revpdf-release; };
}
