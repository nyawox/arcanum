{ stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation {
  pname = "catppuccin-bat";
  version = "0-unstable-2024-12-23";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "bat";
    rev = "699f60fc8ec434574ca7451b444b880430319941";
    hash = "sha256-6fWoCH90IGumAMc4buLRWL0N61op+AuMNN9CAR9/OdI=";
  };

  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -r . $out
  '';
}
