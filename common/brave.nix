# Brave with a seeded initial_preferences ("close window when closing last tab"
# has no policy). `passwordStore` is the Chromium --password-store value:
# gnome-libsecret (gnome-keyring, Mango) or kwallet6 (Plasma).
{ pkgs, passwordStore }:
(pkgs.brave.override {
  commandLineArgs = "--password-store=${passwordStore}";
}).overrideAttrs
  (old: {
    postInstall = (old.postInstall or "") + ''
      printf '%s\n' '{"brave":{"enable_closing_last_tab":false,"tabs":{"vertical_tabs_enabled":true}}}' \
        > "$out/opt/brave.com/brave/initial_preferences"
    '';
  })
