{ stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation {
  pname = "catppuccin-tridactyl";
  version = "0-unstable-2022-05-26";

  src = fetchFromGitHub {
    owner = "lonepie";
    repo = "catppuccin-tridactyl";
    rev = "a77c65f7ab5946b37361ae935d2192a9a714f960";
    hash = "sha256-LjLMq7vUwDdxgpdP9ClRae+gN11IPc+XMsx8/+bwUy4=";
  };

  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -r . $out
  '';
}
