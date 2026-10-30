{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  fetchurl,
  copyDesktopItems,
  makeDesktopItem,
  makeWrapper,
  electron,
}:

# FLACI (flaci.com) as a desktop app: formal languages, automata, grammars,
# compilers. Replaces nixpkgs' flaci (gitmh/FLACI from 2024-12, no desktop
# entry) with the fork legymhueck/FLACI: newest upstream state plus main.js and
# package.json updated for current Electron (same source as the AUR package
# legymhueck/FLACI_PKGBUILD).
#
# At runtime FLACI needs only Electron and its static files, so no npm build:
# the fork no longer ships libs/ng-sortable/dist and its lock files do not list
# ng-sortable, so the dist files come straight from the npm tarball.
let
  ngSortable = fetchurl {
    url = "https://registry.npmjs.org/ng-sortable/-/ng-sortable-1.3.8.tgz";
    hash = "sha256-Srpgqy1I9RJHte7ZoSEjeMe6zA2wnRBrMkn6zVsaa7Y=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "flaci";
  version = "0-unstable-2026-04-03";

  src = fetchFromGitHub {
    owner = "legymhueck";
    repo = "FLACI";
    rev = "b50e5fb7e3287ff4e2935b24dcaa81063db3e5df";
    hash = "sha256-LcPIHknrX9zkIgycaDxWAZJAsIn0bJxboh0IVFUI/6E=";
  };

  nativeBuildInputs = [
    copyDesktopItems
    makeWrapper
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    app="$out/share/flaci"
    mkdir -p "$app"
    cp -r . "$app"
    rm -f "$app"/{build.command,flaciLogo.icns,flaciLogo.ico,package-lock.json,npm-shrinkwrap.json}

    mkdir -p "$app/libs/ng-sortable/dist"
    tar -xzf ${ngSortable} -C "$app/libs/ng-sortable/dist" --strip-components=2 package/dist

    install -Dm644 flaciLogo.png "$out/share/icons/hicolor/512x512/apps/flaci.png"

    makeWrapper ${lib.getExe electron} "$out/bin/flaci" \
      --add-flags "$app" \
      --add-flags "--no-sandbox"
    # Name of the nixpkgs package's command
    ln -s flaci "$out/bin/FLACI"

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "flaci";
      desktopName = "FLACI";
      comment = "Formale Sprachen, abstrakte Automaten, Compiler und Interpreter";
      exec = "flaci %U";
      icon = "flaci";
      terminal = false;
      categories = [
        "Education"
        "ComputerScience"
      ];
    })
  ];

  meta = {
    description = "Formal languages, abstract automata, grammars and compilers (FLACI desktop app)";
    homepage = "https://flaci.com";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "flaci";
  };
}
