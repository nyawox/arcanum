{
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  alsa-lib,
}:
rustPlatform.buildRustPackage {
  name = "nu_plugin_audio_hook";
  version = "0.2.0-unstable-2024-12-23";
  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = "nu_plugin_audio_hook";
    rev = "8c9290301e672bddef77f6c92c5929144c2f7c5e";
    hash = "sha256-5iCZWNZ1j5AdVSFyiGJ/85pkyRWV7fjFd95LMopeuZ0=";
  };
  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
  ];
  buildInputs = [
    alsa-lib
  ];
  cargoHash = "sha256-RVYZunD2DsIGOv4+njtuEBuZpE5vqSUTtDQ1KTUnMXw=";
  meta.mainProgram = "nu_plugin_audio_hook";
}
