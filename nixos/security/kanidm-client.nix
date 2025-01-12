{
  arcanum,
  pkgs,
  ...
}:
{
  content = {
    services.kanidm = {
      enableClient = true;
      # pin the same version the server is running on
      # can't have the same priority as the package in server module
      package = pkgs.kanidmWithSecretProvisioning_1_4;
      clientSettings = {
        uri = "https://account.${arcanum.domain}";
        verify_ca = true;
        verify_hostnames = true;
      };
    };
  };
}
