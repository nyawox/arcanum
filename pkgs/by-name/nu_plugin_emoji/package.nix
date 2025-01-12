{
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage {
  name = "nu_plugin_emoji";
  version = "0.10.0-unstable-2024-12-25";
  src = fetchFromGitHub {
    owner = "fdncred";
    repo = "nu_plugin_emoji";
    rev = "447e6a02cd98286702735c33e75771086db80bb0";
    hash = "sha256-7dxWvwktuIBJVWgg6mDA/a3qHp+MlBx7Q/HijLR7FUg=";
  };
  cargoHash = "sha256-NOeQO+1A3RZfD9AUN7hDrk0mAIAHqc0PT8EzmNeNluM=";
  meta.mainProgram = "nu_plugin_emoji";
}
