{
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage {
  name = "nu_plugin_dns";
  version = "3.0.6-unstable-2024-12-09";
  src = fetchFromGitHub {
    owner = "dead10ck";
    repo = "nu_plugin_dns";
    rev = "0453d9adbbadc00e4ff22261cf464d10ea4a4ccc";
    hash = "sha256-a1EQV/UX4+gB14jHMReLFbOmabZ5r40FgaHO+60IPME=";
  };
  cargoHash = "sha256-kwKpCTuK3ZPV8oASGha62FhCCR6UHl3994Q1iKQfLD0=";
  meta.mainProgram = "nu_plugin_dns";
}
