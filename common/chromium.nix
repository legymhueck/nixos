# Chromium as the secondary browser (Firefox stays the default, the http(s)
# MIME handlers in nixos-<variant>/home.nix): claude.ai and sites that work
# better with the Chrome engine run here. The Claude, uBlock Origin Lite and
# Proton Pass extensions preinstall by id from the Chrome Web Store; Home
# Manager writes External Extensions JSON into ~/.config/chromium and the
# store's update URL then fetches the CRXs and their updates. That URL only
# works on plain chromium (ungoogled-chromium disables it by design), which is
# why this is not ungoogled-chromium. The password store differs per desktop
# and is set via commandLineArgs in nixos-<variant>/home.nix.
# System-wide policies (blank new tab) are in common/base.nix.
{ pkgs, ... }:
{
  programs.chromium = {
    enable = true;
    package = pkgs.chromium;
    extensions = [
      { id = "fcoeoabgfenejglbffodgkkbkcdhcgfn"; } # Claude
      { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; } # uBlock Origin Lite
      { id = "ghmbeldphafepmbegfdlkpapadhbakde"; } # Proton Pass
    ];
  };
}
