{
  buildHomeAssistantComponent,
  fetchFromGitHub,
  ...
}:
buildHomeAssistantComponent {
  owner = "Haoyu-UT";
  domain = "nature_remo";
  version = "1.0.8-unstable-2024-09-06";
  src = fetchFromGitHub {
    owner = "Haoyu-UT";
    repo = "HomeAssistantNatureRemo";
    rev = "b6d034ce379f4ce51beac3bdc40a728d0162d0e7";
    hash = "sha256-hXXUg2dRnIhYEYZVR0LE4Z1NQtzmnPoBUrFQlRB0Iuk=";
  };
}
