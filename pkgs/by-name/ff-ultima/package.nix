{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "ff-ultima";
  version = "1.8.6"; # 1.9+ require FF 130+

  src = fetchFromGitHub {
    owner = "soulhotel";
    repo = "ff-ultima";
    rev = version;
    hash = "sha256-kKvY63Vqt0FeZfDtns89YRLzOru6/8Tv9Mqr0Ix05rw=";
  };

  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -r . $out
  '';
}
