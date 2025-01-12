{
  fetchFromGitHub,
  buildGoModule,
}:
buildGoModule {
  name = "adguard-exporter";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "henrywhitaker3";
    repo = "adguard-exporter";
    rev = "1cd2e20d5ca5c97e2f729c8283e255135cc01e5c";
    hash = "sha256-zJnmEj8kcaUCxxuxMR6l0xaUtqnZh68VPcFZVrEafnM=";
  };
  vendorHash = "sha256-Y2wIDO4W5xIHAxk/W3GXiXQ8pld/pBOedc/F2K9MPgc=";
}
