{
  lib,
  rustPlatform,
  src,
  adwaita-icon-theme,
  cairo,
  dbus,
  gdk-pixbuf,
  gettext,
  glib,
  glib-networking,
  gnupg,
  gsettings-desktop-schemas,
  gtk4,
  libadwaita,
  openssl,
  pango,
  pkg-config,
  poppler,
  wayland,
  webkitgtk_6_0,
  wrapGAppsHook4,
}:

let
  cargoToml = lib.importTOML "${src}/Cargo.toml";
in
rustPlatform.buildRustPackage {
  pname = "hylki";
  inherit (cargoToml.package) version;
  inherit src;

  cargoLock.lockFile = "${src}/Cargo.lock";

  nativeBuildInputs = [
    pkg-config
    glib # glib-compile-resources, used by build.rs (glib-build-tools)
    gettext # msgfmt for .desktop file and translations
    wrapGAppsHook4
  ];

  buildInputs = [
    gtk4
    libadwaita
    webkitgtk_6_0
    poppler # poppler-glib
    cairo
    pango
    gdk-pixbuf
    glib
    openssl
    dbus
    wayland
    gettext
    adwaita-icon-theme
    glib-networking # TLS for WebKit
    gsettings-desktop-schemas
  ];

  # Tests expect a display / session bus.
  doCheck = false;

  postInstall = ''
    appid=co.hyprlab.Hylki

    # Icons
    for size in 256x256 512x512; do
      install -Dm644 data/icons/hicolor/$size/apps/$appid.png \
        $out/share/icons/hicolor/$size/apps/$appid.png
    done
    install -Dm644 data/icons/hicolor/scalable/apps/$appid.svg \
      $out/share/icons/hicolor/scalable/apps/$appid.svg
    install -Dm644 data/icons/hicolor/symbolic/apps/$appid-symbolic.svg \
      $out/share/icons/hicolor/symbolic/apps/$appid-symbolic.svg

    # Desktop entry (with translations merged in)
    install -d $out/share/applications
    msgfmt --desktop --template=data/$appid.desktop -d po \
      -o $out/share/applications/$appid.desktop

    # Translations
    for po in po/*.po; do
      [ -e "$po" ] || continue
      lang=$(basename "$po" .po)
      install -d $out/share/locale/$lang/LC_MESSAGES
      msgfmt -o $out/share/locale/$lang/LC_MESSAGES/hylki.mo "$po"
    done
  '';

  # gnupg is used for OpenPGP sign/encrypt/decrypt.
  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : ${lib.makeBinPath [ gnupg ]}
    )
  '';

  meta = {
    description = "Fast, GNOME-native email client built with Rust and libadwaita";
    homepage = "https://hylki.hyprlab.co";
    license = lib.licenses.agpl3Plus;
    mainProgram = "hylki";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
