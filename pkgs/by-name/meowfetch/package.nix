{ stdenvNoCC, fetchgit }:

stdenvNoCC.mkDerivation {
  pname = "meowfetch";
  version = "0.6-unstable-2024-06-08";

  src = fetchgit {
    url = "https://ravy.dev/mint/meowfetch";
    rev = "20424e93a4108d8fa25203a002477d2c2478da0b";
    sha256 = "0gji8fy72m1wmnp4dm508j88ihmcgwz16pliz7ha6j0k9m1pi1f4";
  };

  dontBuild = true;
  installPhase = ''
    mkdir -p $out/bin
    cp bin/meowfetch $out/bin/meowfetch
    chmod +x $out/bin/meowfetch
  '';
}
