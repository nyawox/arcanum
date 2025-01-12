{
  arcanum,
  config,
  lib,
  ...
}:
with lib;
{
  content = {
    sops.secrets.oauth2-env = {
      sopsFile = "${arcanum.secretPath}/oauth2-secrets.yaml";
      owner = "oauth2-proxy";
      format = "yaml";
      restartUnits = [ "oauth2-proxy.service" ];
    };
    services.oauth2-proxy = {
      enable = true;
      cookie = {
        domain = ".${arcanum.domain}";
        secret = null;
        expire = "1440m";
        secure = true;
      };
      clientSecret = null;

      proxyPrefix = "/oauth2";
      reverseProxy = true;
      approvalPrompt = "auto";
      setXauthrequest = true;
      clientID = "oauth2-proxy";
      httpAddress = "http://0.0.0.0:16544";
      redirectURL = "https://oauth2.${arcanum.domain}/oauth2/callback";

      provider = "oidc";
      redeemURL = "https://account.${arcanum.domain}/oauth2/token";
      loginURL = "https://account.${arcanum.domain}/ui/oauth2";
      oidcIssuerUrl = "https://account.${arcanum.domain}/oauth2/openid/oauth2-proxy";
      validateURL = "https://account.${arcanum.domain}/oauth2/token/introspect";
      profileURL = "https://account.${arcanum.domain}/oauth2/openid/oauth2-proxy/userinfo";

      email.domains = [ "*" ];
      scope = "openid profile email";

      extraConfig = {
        provider-display-name = "${arcanum.serviceName} Account";
        code-challenge-method = "S256"; # PKCE
        whitelist-domain = ".${arcanum.domain}";
        skip-provider-button = true;
        set-authorization-header = true;
        pass-access-token = true;
        skip-jwt-bearer-tokens = true;
        upstream = "static://202";
      };
    };
    systemd.services.oauth2-proxy = {
      after = [ "kanidm.service" ];
      serviceConfig = {
        EnvironmentFile = [ config.sops.secrets.oauth2-env.path ];
        RuntimeDirectory = "oauth2-proxy";
        RuntimeDirectoryMode = "0750";
        UMask = "007";
        RestartSec = "60";
      };
    };

  };
  persist.directories = singleton {
    directory = "/var/lib/oauth2-proxy";
    user = "oauth2-proxy";
    group = "oauth2-proxy";
    mode = "0750";
  };
}
