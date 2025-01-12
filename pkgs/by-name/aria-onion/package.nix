{ stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation {
  pname = "aria-onion";
  version = "0-unstable-2024-10-07";

  src = fetchFromGitHub {
    owner = "sn0b4ll";
    repo = "aria2-onion-downloader";
    rev = "ca89beca9b1f9975a2b1e4281f1daa7313c93f99";
    hash = "sha256-5+ef1YnkY7l/xn0kGiAHfk5o20XRjPA7xeax+hoEdlI=";
  };

  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -r . $out
  '';
}
