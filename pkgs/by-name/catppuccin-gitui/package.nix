{ stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation {
  pname = "catppuccin-gitui";
  version = "pre-0.26.2-unstable-2024-05-25";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "gitui";
    rev = "c7661f043cb6773a1fc96c336738c6399de3e617";
    hash = "sha256-CRxpEDShQcCEYtSXwLV5zFB8u0HVcudNcMruPyrnSEk=";
  };

  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -r . $out
  '';
}
