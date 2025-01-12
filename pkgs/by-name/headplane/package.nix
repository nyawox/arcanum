{
  lib,
  stdenv,
  fetchFromGitHub,
  pnpm_9,
  makeWrapper,
  nodejs,
  git,
}:
stdenv.mkDerivation rec {
  pname = "headplane";
  version = "0.4.1-unstable-2025-01-20";

  src = fetchFromGitHub {
    owner = "tale";
    repo = "headplane";
    rev = "2d47f1b952e9f2c799d274a40676d05d54584297";
    hash = "sha256-NLlDvLNblVR+sRKcMRqZmjsSIZht/tSHssMIRCDMmYQ=";
    leaveDotGit = true;
  };

  nativeBuildInputs = [
    pnpm_9.configHook
    makeWrapper
    nodejs
    git
  ];

  pnpmDeps = pnpm_9.fetchDeps {
    inherit pname version src;
    hash = "sha256-R3j2hpd9JB3Y5TWjZS27sMZS0VUBR4bVx9iodo6bAqc=";
  };

  buildPhase = ''
    runHook preBuild
    pnpm build
    pnpm prune --prod
    runHook postBuild
  '';

  installPhase = ''
    mkdir -p $out/{bin,share/headplane}
    cp -r {build,node_modules} $out/share/headplane/
     sed -i 's;/build/source/node_modules/react-router/dist/development/index.mjs;react-router;' $out/share/headplane/build/headplane/server.js
     sed -i 's;define_process_env_default.PORT;process.env.PORT;' $out/share/headplane/build/headplane/server.js
     makeWrapper ${lib.getExe nodejs} $out/bin/headplane \
         --chdir $out/share/headplane \
         --set BUILD_PATH $out/share/headplane/build \
         --set NODE_ENV production \
         --add-flags $out/share/headplane/build/headplane/server.js
     runHook postInstall
  '';

  meta.mainProgram = "headplane";
}
