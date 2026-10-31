# Local packages, added to pkgs by the overlay in common/base.nix and exposed
# as flake outputs (`nix build .#hylki`). Upstream sources that are not plain
# fetches are flake inputs (hylki-src, revpdf-release).
{ inputs }:
final: _prev: {
  bibox = final.callPackage ./bibox/package.nix { };
  cornelsen-offline-lernen = final.callPackage ./cornelsen-offline-lernen/package.nix { };
  doublecmd-qt6 = final.callPackage ./doublecmd-qt6/package.nix { };
  # Replaces nixpkgs' flaci (older, no desktop entry), see the package.
  flaci = final.callPackage ./flaci/package.nix { };
  hylki = final.callPackage ./hylki/package.nix { src = inputs.hylki-src; };
  # Logseq: nixpkgs pins it to Electron 39, which is EOL and now refused by Nix;
  # use the first non-EOL Electron (42) instead.
  logseq = _prev.logseq.override { electron_39 = final.electron_42; };
  mtplayer = final.callPackage ./mtplayer/package.nix { };
  revpdf = final.callPackage ./revpdf/package.nix { inherit (inputs) revpdf-release; };
}
