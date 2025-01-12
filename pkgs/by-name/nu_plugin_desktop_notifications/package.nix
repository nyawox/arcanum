{
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage {
  name = "nu_plugin_desktop_notifications";
  version = "1.2.4-unstable-2024-12-23";
  src = fetchFromGitHub {
    owner = "FMotalleb";
    repo = "nu_plugin_desktop_notifications";
    rev = "cfeeac31e29ef66b6b53cfa1bb5972f5d3da388c";
    hash = "sha256-X2Sp+D4PB4U4o+zwYlewPudWsoC+gE1O4fr2vYqsWkM=";
  };
  cargoHash = "sha256-2sPV/7Tt8Sb64cSEYkdlOf7lLozpxVn/ZYxv9t137MI=";
  meta.mainProgram = "nu_plugin_desktop_notifications";

}
