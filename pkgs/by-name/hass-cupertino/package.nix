{
  buildHomeAssistantComponent,
  fetchFromGitHub,
  ...
}:
buildHomeAssistantComponent {
  owner = "AlwardL24";
  domain = "cupertino";
  version = "6.0.0";
  src = fetchFromGitHub {
    owner = "AlwardL24";
    repo = "HomeAssistant-SF-Icons";
    rev = "v6.0.0";
    hash = "sha256-E+tiw/M0bvKZmYEZm6fESQdU9qmOZOxMJtBFH1WSsMI=";
  };
}
