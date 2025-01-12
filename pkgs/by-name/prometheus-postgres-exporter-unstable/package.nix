{
  fetchFromGitHub,
  prometheus-postgres-exporter,
}:
prometheus-postgres-exporter.overrideAttrs (_old: {
  name = "prometheus-postgres-exporter-unstable";
  version = "0.16.0-unstable-2025-01-13";

  src = fetchFromGitHub {
    owner = "prometheus-community";
    repo = "postgres_exporter";
    rev = "7d4c278221e95ddbc62108973e5828a3ffaa2eb8";
    hash = "sha256-6WH6Yls172untyxNrW2pwXMFgz35qyrUpML5KU/n/+k=";
  };
  vendorHash = "sha256-y0Op+FxzOCFmZteHOuqnOcqQlQ0t10Xf+3mSsQEJiPg=";
})
