{ stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation {
  pname = "catppuccin-alacritty";
  version = "yaml-unstable-2024-10-28";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "alacritty";
    rev = "f6cb5a5c2b404cdaceaff193b9c52317f62c62f7";
    hash = "sha256-H8bouVCS46h0DgQ+oYY8JitahQDj0V9p2cOoD4cQX+Q=";
  };

  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -r . $out
  '';
}
