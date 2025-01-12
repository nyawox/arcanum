{ stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation {
  pname = "catppuccin-yazi";
  version = "0-unstable-2024-12-17";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "yazi";
    rev = "5d3a1eecc304524e995fe5b936b8e25f014953e8";
    hash = "sha256-UVcPdQFwgBxR6n3/1zRd9ZEkYADkB5nkuom5SxzPTzk=";
  };

  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -r . $out
  '';
}
