{
  lib,
  stdenvNoCC,
  fetchurl,
  appimage-run,
  copyDesktopItems,
  libepoxy,
  makeDesktopItem,
  makeWrapper,
  revpdf-release,
}:

stdenvNoCC.mkDerivation {
  pname = "revpdf";
  version = "5.0.0";

  src = fetchurl {
    url = "https://github.com/Pawandeep-prog/revpdf-release/releases/download/v5.0.0/revpdf_editor-x86_64.AppImage";
    hash = "sha256-SydYF+1qSYNDe/ywp9ii0l0pAxQ9LTJ5YLZFidHFrgY=";
  };

  nativeBuildInputs = [
    copyDesktopItems
    makeWrapper
  ];
  buildInputs = [ appimage-run ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src" "$out/share/revpdf/revpdf.AppImage"
    install -Dm644 ${revpdf-release}/LICENSE "$out/share/licenses/revpdf/LICENSE"
    install -Dm644 ${revpdf-release}/com.revpdf.editor.png \
      "$out/share/icons/hicolor/512x512/apps/revpdf.png"

    makeWrapper ${appimage-run}/bin/appimage-run "$out/bin/revpdf" \
      --add-flags "$out/share/revpdf/revpdf.AppImage" \
      --prefix LD_LIBRARY_PATH : ${libepoxy}/lib

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "revpdf";
      desktopName = "RevPDF Editor";
      comment = "Edit and manage PDF files";
      exec = "revpdf %U";
      icon = "revpdf";
      terminal = false;
      categories = [
        "Office"
        "Graphics"
      ];
      mimeTypes = [ "application/pdf" ];
    })
  ];

  meta = {
    description = "Offline PDF editor";
    homepage = "https://www.revpdf.com";
    changelog = "https://github.com/Pawandeep-prog/revpdf-release/releases/tag/v5.0.0";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "revpdf";
  };
}
