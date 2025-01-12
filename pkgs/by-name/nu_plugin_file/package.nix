{
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage {
  name = "nu_plugin_file";
  version = "0.12.0-unstable-2024-12-25";
  src = fetchFromGitHub {
    owner = "fdncred";
    repo = "nu_plugin_file";
    rev = "f9023b8cf3e5ac455023929ced504ecd2a9b5592";
    hash = "sha256-ML0ZKsF+fEj5KU0ZLNsWDLyXT+iRvW9OtJ7hZ9ZuXHE=";
  };
  cargoHash = "sha256-4utyCLrsbmsMkwB0RtXBmryo8qIx9IopGEP6fIcNmMI=";
  meta.mainProgram = "nu_plugin_file";

}
