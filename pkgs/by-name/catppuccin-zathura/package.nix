{ stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation {
  pname = "catppuccin-zathura";
  version = "0-unstable-2024-04-04";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "zathura";
    rev = "0adc53028d81bf047461bc61c43a484d11b15220";
    hash = "sha256-/vD/hOi6KcaGyAp6Az7jL5/tQSGRzIrf0oHjAJf4QbI=";
  };

  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -r . $out
  '';
}
