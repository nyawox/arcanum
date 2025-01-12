{
  rustPlatform,
  fetchFromGitHub,
  avahi,
  cudaPackages,
  linuxPackages,
  ffmpeg_6,
  libpulseaudio,
  openssl,
  libopus,
  glibc,
  enet,
  gcc,
  pkg-config,
  llvmPackages,
  cmake,
}:
rustPlatform.buildRustPackage rec {
  pname = "moonshine";
  version = "0.5.0-unstable-2024-12-19";
  src = fetchFromGitHub {
    owner = "hgaiser";
    repo = "moonshine";
    rev = "50a2d5994f5212e810261e2657a6129fdf95b1ba";
    hash = "sha256-8sRaOna+qWgGBoeUyrExYb1FEAC51GnosTloTXtckgk=";
  };
  buildInputs = [
    avahi
    cudaPackages.cudatoolkit
    linuxPackages.nvidia_x11
    ffmpeg_6
    libpulseaudio
    openssl
    libopus
    glibc
    enet
  ];
  nativeBuildInputs = [
    gcc
    pkg-config
    llvmPackages.libclang
    cmake
    rustPlatform.bindgenHook
  ];
  CUDA_ROOT = "${cudaPackages.cudatoolkit}";
  preBuild = ''
    export LD_LIBRARY_PATH=${linuxPackages.nvidia_x11}/lib:$LD_LIBRARY_PATH
  '';
  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "ffmpeg-next-7.1.0" = "sha256-DahtqkOBOA5q7yIvq2/mUPCTOu6fF2ZlGuVrYaOTpq8=";
      "ffmpeg-sys-next-7.1.0" = "sha256-Zh1GIoDhxYJjWSPhiyGtiooqoF9DoAnAtS5t3s4sBlM=";
      "reed-solomon-erasure-6.0.0" = "sha256-bSIl+Fmz74CgwYd6Qhx2KiIXJiuj6Y2DKFcVXlM+liY=";
    };
  };
  meta.mainProgram = "moonshine";
}
