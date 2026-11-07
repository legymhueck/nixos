{
  imports = [
    ../common/home.nix
    ./home-packages.nix
  ];

  # Chromium (../common/chromium.nix) uses the running desktop's wallet.
  programs.chromium.commandLineArgs = [ "--password-store=kwallet6" ];
}
