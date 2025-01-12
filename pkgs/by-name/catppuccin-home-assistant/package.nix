{ stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation {
  pname = "catppuccin-home-assistant";
  version = "1.0.2-unstable-2024-03-20";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "home-assistant";
    rev = "e877188ca467e7bbe8991440f6b5f6b3d30347fc";
    hash = "sha256-eUqYlaXNLPfaKn3xcRm5AQwTOKf70JF8cepibBb9KXc=";
  };

  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -r . $out
  '';
}
