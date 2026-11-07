{
  lib,
  stdenv,
  fetchurl,
  alsa-lib,
  asar,
  atk,
  cairo,
  copyDesktopItems,
  cups,
  dbus,
  electron,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libnotify,
  libsecret,
  libuuid,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxrandr,
  libxrender,
  libxshmfence,
  libxtst,
  makeDesktopItem,
  makeWrapper,
  mesa,
  nodejs,
  nspr,
  nss,
  pango,
  systemd,
  unzip,
}:

let
  runtimeLibs = [
    alsa-lib
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libxtst
    libdrm
    libnotify
    libsecret
    libuuid
    libxcb
    libxshmfence
    mesa
    nspr
    nss
    pango
    systemd
  ];
in
stdenv.mkDerivation {
  pname = "cornelsen-offline-lernen-bin";
  version = "44.0.0";

  src = fetchurl {
    url = "https://ebook.cornelsen.de/uma20/public/v2/uma/offline/win";
    hash = "sha512-+b2++Zs2yFx0WNqVpox7oqtRXq3cNHY2uXk4mzFuc3B4WthV6ifSpK9jez/OR/wLmLku8nPwGxgMVyQH4nvIUA==";
  };

  nativeBuildInputs = [
    asar
    copyDesktopItems
    makeWrapper
    nodejs
    unzip
  ];
  buildInputs = [ electron ];

  unpackPhase = ''
    runHook preUnpack
    unzip $src -d source
    cd source
    runHook postUnpack
  '';

  # The Windows build ships a platform-independent app.asar: patch it so the
  # app works offline (see patch-asar.js) and run it with the nixpkgs Electron.
  buildPhase = ''
    runHook preBuild

    ASAR_PATH=$(find . -type f -path "*/resources/app.asar" | head -n 1)
    if [ -z "$ASAR_PATH" ]; then
      echo "ERROR: source app.asar not found!"
      exit 1
    fi

    asar extract "$ASAR_PATH" unpacked_asar
    node ${./patch-asar.js} unpacked_asar
    asar pack unpacked_asar app.asar

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm644 app.asar $out/share/cornelsen-offline-lernen/app.asar

    # The launcher copies app.asar to a writable place on the first start.
    install -Dm755 ${./launcher.sh} $out/bin/cornelsen-offline-lernen-bin
    substituteInPlace $out/bin/cornelsen-offline-lernen-bin \
      --subst-var-by out "$out" \
      --subst-var-by electron "${electron}"
    wrapProgram $out/bin/cornelsen-offline-lernen-bin \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs} \
      --set NODE_OPTIONS "--no-warnings"

    icons=$out/share/icons/hicolor
    install -Dm644 ${./icon16.png} $icons/16x16/apps/cornelsen-offline-lernen.png
    install -Dm644 ${./icon32.png} $icons/32x32/apps/cornelsen-offline-lernen.png
    install -Dm644 ${./icon96.png} $icons/96x96/apps/cornelsen-offline-lernen.png

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "cornelsen-offline-lernen-bin";
      desktopName = "Cornelsen Offline Lernen";
      comment = "Cornelsen Offline Lernen Electron Application";
      exec = "cornelsen-offline-lernen-bin %U";
      icon = "cornelsen-offline-lernen";
      terminal = false;
      categories = [ "Education" ];
      mimeTypes = [ "x-scheme-handler/uma-offline" ];
    })
  ];

  meta = {
    description = "Offline reader for Cornelsen e-books";
    homepage = "https://www.cornelsen.de";
    platforms = [ "x86_64-linux" ];
    mainProgram = "cornelsen-offline-lernen-bin";
  };
}
