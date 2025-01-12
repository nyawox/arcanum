{
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage {
  name = "nu_plugin_clipboard";
  version = "0.101.0-unstable-2025-01-03";
  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = "nu_plugin_clipboard";
    rev = "a2f982e09fd72d83207772c393a311abb07c19d1";
    hash = "sha256-qS8dOtOLq8grhmori9w1d/zrhu1X3Qk51y+v/LTAxO8=";
  };
  cargoHash = "sha256-ErmfPqK89q+SNk/THaz0RzptaV/abflbfs8h0ebTKpw=";
  meta.mainProgram = "nu_plugin_clipboard";

}
