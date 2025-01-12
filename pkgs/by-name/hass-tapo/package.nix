{
  buildHomeAssistantComponent,
  fetchFromGitHub,
  python313Packages,
  ...
}:
buildHomeAssistantComponent {
  owner = "petretiandrea";
  domain = "tapo";
  version = "3.1.4-unstable-2024-12-30";
  src = fetchFromGitHub {
    owner = "petretiandrea";
    repo = "home-assistant-tapo-p100";
    rev = "eb07968923ad8d909a3f3dd83a0352be95527ada";
    hash = "sha256-AwvS7UUMUvE12qt4Uu+ApTfNhsnh1Hi3EPTkuZNRiCc=";
  };
  propagatedBuildInputs = [
    python313Packages.plugp100
  ];
}
