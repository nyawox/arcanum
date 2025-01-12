{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "mido";
  version = "0-unstable-2024-03-23";

  src = fetchFromGitHub {
    owner = "ElliotKillick";
    repo = "Mido";
    rev = "25d9fbdf20842d8f611e54e92f186901dbb3a04a";
    hash = "sha256-8jCmGnrraaKHUE66o5MsxGWJCpglXrqJUEaDv0NIIJo=";
  };

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp Mido.sh $out/bin/Mido
    patchShebangs $out/bin/Mido
  '';

  meta.mainProgram = "Mido";
}
