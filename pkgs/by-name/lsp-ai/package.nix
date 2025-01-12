{
  lib,
  rustPlatform,
  fetchCrate,
  openssl,
  pkg-config,
}:
rustPlatform.buildRustPackage rec {
  pname = "lsp-ai";
  version = "0.7.0";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-Q4Tv5W1Ppb80+8l5CUFHqn9eFCvyNd5hVfPAB/AfIs4=";
  };

  OPENSSL_NO_VENDOR = 1;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  cargoHash = "sha256-rgAwxeOQem//M6SXG3JTP7mOqn8MOUUoRNWN2hCAs24=";

  doCheck = false;

  # buildFeatures = [
  #   "llama_cpp"
  #   "metal"
  # ];

  meta = with lib; {
    description = "An open-source language server that serves as a backend for AI-powered functionality";
    homepage = "https://github.com/SilasMarvin/lsp-ai";
    license = licenses.mit;
    mainProgram = "lsp-ai";
  };
}
