{
  cfg,
  config,
  lib,
  pkgs,
  arcanum,
  ...
}:
with lib;
{
  options.port = mkOption {
    type = types.int;
    default = 9191;
  };
  content = {
    modules.networking.headscale.enable = mkForce true;

    sops.secrets.headplane-env = {
      sopsFile = "${arcanum.secretPath}/headscale-secrets.yaml";
      format = "yaml";
    };

    systemd.services.headplane = {
      description = "Headscale Admin Console";
      after = [
        "network.target"
        "headscale.service"
        "kanidm.service"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = config.services.headscale.user;
        Group = config.services.headscale.group;
        Environment = [
          "HOST=0.0.0.0"
          "PORT=${toString cfg.port}"
          "CONFIG_FILE=${
            (pkgs.formats.yaml { }).generate "headscale.yaml" config.services.headscale.settings
          }"
          "COOKIE_SECURE=true"
          "HEADSCALE_INTEGRATION=proc"
          "HEADSCALE_URL=${config.services.headscale.settings.server_url}"
          "OIDC_CLIENT_ID=headscale"
          "OIDC_CLIENT_SECRET_METHOD=client_secret_basic"
          "OIDC_ISSUER=https://account.${arcanum.domain}/oauth2/openid/headscale"
          "OIDC_REDIRECT_URI=https://hs.${arcanum.domain}/admin/oidc/callback"
          "DISABLE_API_KEY_LOGIN=true"
        ];
        EnvironmentFile = config.sops.secrets.headplane-env.path;
        ExecStart = "${getExe pkgs.headplane}";
        Restart = "always";
      };
    };
  };
}
