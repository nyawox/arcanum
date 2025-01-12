{
  buildHomeAssistantComponent,
  fetchFromGitHub,
  python313Packages,
  ...
}:
buildHomeAssistantComponent {
  owner = "christiaangoossens";
  domain = "auth_oidc";
  version = "0.5.1-alpha";
  src = fetchFromGitHub {
    owner = "christiaangoossens";
    repo = "hass-oidc-auth";
    rev = "b39a65ff746a37feade82459e2e4063ec7da3984";
    hash = "sha256-ZYuQhkJ6ne0kIdF9P4796R9pzCJ+BbQNW3fmxgpTFns=";
  };
  propagatedBuildInputs = with python313Packages; [
    python-jose
    aiofiles
    jinja2
    bcrypt
  ];
}
