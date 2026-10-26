{
  lib,
  stdenv,
  fetchurl,
  alsa-lib,
  atk,
  cairo,
  copyDesktopItems,
  ffmpeg,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libGL,
  libx11,
  libxext,
  libxi,
  libxkbcommon,
  libxrender,
  libxtst,
  libxxf86vm,
  makeDesktopItem,
  makeWrapper,
  pango,
  temurin-bin-21,
  unzip,
  vlc,
}:

let
  # Loaded by the JavaFX GUI at run time (LD_LIBRARY_PATH).
  runtimeLibs = [
    libx11
    libxext
    libxi
    libxrender
    libxtst
    libxxf86vm
    glib
    gtk3
    cairo
    pango
    gdk-pixbuf
    atk
    alsa-lib
    libGL
    freetype
    fontconfig
    libxkbcommon
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "mtplayer";
  version = "22__2026.08.22";

  src = fetchurl {
    url = "https://github.com/xaverW/MTPlayer/releases/download/version-22/MTPlayer-${finalAttrs.version}.zip";
    hash = "sha256-7TauWRVNDumAaN6BOHFndh2iVpLk2EUfJCuF4tY6iDM=";
  };

  nativeBuildInputs = [
    copyDesktopItems
    makeWrapper
    unzip
  ];
  buildInputs = [
    temurin-bin-21
    vlc
    ffmpeg
  ]
  ++ runtimeLibs;

  unpackPhase = ''
    runHook preUnpack
    unzip $src -d source
    cd source
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/mtplayer
    cp -r * $out/share/mtplayer/

    jar=$(find $out/share/mtplayer -iname "mtplayer.jar" | head -n 1)
    if [ -z "$jar" ]; then
      echo "Error: Could not find MTPlayer.jar inside the archive!"
      exit 1
    fi

    # Java plus the players MTPlayer starts (PATH) and the GUI libraries.
    makeWrapper ${temurin-bin-21}/bin/java $out/bin/mtplayer \
      --add-flags "-jar $jar" \
      --prefix PATH : ${
        lib.makeBinPath [
          vlc
          ffmpeg
        ]
      } \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs}

    install -Dm444 "$out/share/mtplayer/MTPlayer/MTPlayer.png" \
      "$out/share/icons/hicolor/512x512/apps/mtplayer.png"

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "mtplayer";
      desktopName = "MTPlayer";
      comment = "Access to Mediathek of public tv stations";
      exec = "mtplayer";
      icon = "mtplayer";
      categories = [
        "AudioVideo"
        "Player"
      ];
    })
  ];

  meta = {
    description = "Media player for the libraries of German, Austrian and Swiss public broadcasters";
    homepage = "https://github.com/xaverW/MTPlayer";
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "mtplayer";
  };
})
