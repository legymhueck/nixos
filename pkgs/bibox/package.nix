{
  lib,
  stdenv,
  fetchurl,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  autoPatchelfHook,
  cairo,
  cups,
  dbus,
  dpkg,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  inetutils,
  libdrm,
  libgbm,
  libGL,
  libsecret,
  libuuid,
  libva,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  libxrender,
  libxshmfence,
  libxtst,
  makeWrapper,
  nspr,
  nss,
  pango,
  systemd,
  writeShellScript,
  xdg-utils,
}:

let
  runtimeLibs = [
    gtk3
    pango
    libx11
    libxrandr
    libsecret
    nss
    nspr
    libgbm
    stdenv.cc.cc.lib
    glib
    atk
    at-spi2-atk
    at-spi2-core
    cups
    dbus
    expat
    fontconfig
    freetype
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrender
    libxtst
    libuuid
    libxcb
    libxshmfence
    alsa-lib
    libdrm
    cairo
    libxkbcommon
    gdk-pixbuf
    systemd
    libGL
    libva
  ];

  # Links opened from BiBox must not inherit its LD_LIBRARY_PATH.
  xdgOpen = writeShellScript "xdg-open" ''
    unset LD_LIBRARY_PATH
    exec ${xdg-utils}/bin/xdg-open "$@"
  '';
in
stdenv.mkDerivation (finalAttrs: {
  pname = "bibox";
  version = "3.0.4";

  src = fetchurl {
    name = "BiBox-${finalAttrs.version}.deb";
    url = "https://static.bibox2.westermann.de/electron/autoUpdate/BiBox%20${finalAttrs.version}.deb";
    hash = "sha256-nrmi+pgQfJFY2qLrDPLlUY9TeH21ihTR0xAXYhCKw14=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = runtimeLibs;

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/opt/bibox"
    if [ -d "opt/BiBox 2.0" ]; then
      cp -a "opt/BiBox 2.0/." "$out/opt/bibox/"
    elif [ -d "opt/bibox" ]; then
      cp -a "opt/bibox/." "$out/opt/bibox/"
    else
      cp -a opt/* "$out/opt/bibox/"
    fi

    install -Dm755 ${xdgOpen} "$out/libexec/bibox/xdg-open"

    makeWrapper "$out/opt/bibox/bibox" "$out/bin/bibox" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}" \
      --prefix PATH : "$out/libexec/bibox:${
        lib.makeBinPath [
          inetutils
          xdg-utils
          glib
        ]
      }" \
      --set APPIMAGE "$out/opt/bibox/bibox"

    desktop=usr/share/applications/bibox.desktop
    if [ -f "$desktop" ]; then
      install -Dm644 "$desktop" "$out/share/applications/bibox.desktop"
      sed -i \
        -e "s|Exec=\"/opt/BiBox 2.0/bibox\" %U|Exec=$out/bin/bibox %U|g" \
        -e "s|Exec=\"/opt/bibox/bibox\" %U|Exec=$out/bin/bibox %U|g" \
        -e "s|Icon=/usr/share/icons/hicolor/0x0/apps/bibox2.png|Icon=bibox|g" \
        "$out/share/applications/bibox.desktop"
    fi

    if [ -f usr/share/icons/hicolor/0x0/apps/bibox.png ]; then
      install -Dm644 usr/share/icons/hicolor/0x0/apps/bibox.png \
        "$out/share/icons/hicolor/512x512/apps/bibox.png"
    fi

    runHook postInstall
  '';

  meta = {
    description = "Official client for Westermann textbooks";
    homepage = "https://www.bibox.schule";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "bibox";
  };
})
