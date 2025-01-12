{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs,
  pnpm,
  ...
}:

stdenv.mkDerivation rec {
  pname = "hass-kiosk-mode";
  version = "6.6.0-unstable-2025-01-12";

  src = fetchFromGitHub {
    owner = "NemesisRE";
    repo = "kiosk-mode";
    rev = "b9c984d7f5019cbd352ac453ec9c6ddfde04f5a1";
    hash = "sha256-cD0hLjehblc1spX1A0mG88VzmC3qRjtONKLRgWfRlZ4=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm.configHook
  ];

  pnpmDeps = pnpm.fetchDeps {
    inherit pname version src;
    hash = "sha256-BsM3HA5zMdISwNnGs+9R0C7mykXxkzL56PpkRjfIw2g=";
  };

  buildPhase = ''
    runHook preBuild

    ${lib.getExe pnpm} build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir $out
    install -m0644 ./.hass/config/www/kiosk-mode.js $out

    runHook postInstall
  '';
  doDist = false;

}
