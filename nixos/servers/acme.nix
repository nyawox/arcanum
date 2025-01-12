{
  config,
  lib,
  pkgs,
  arcanum,
  ...
}:
with lib;
let
  tlsa-update = pkgs.writeShellScriptBin "tlsa-update" ''
    #!/usr/bin/env bash
    ${getExe pkgs.curl} -X DELETE "https://desec.io/api/v1/domains/${arcanum.domain}/rrsets/_25._tcp/TLSA/" \
        --header "Authorization: Token ''${DESEC_TOKEN}" \
        --header "Content-Type: application/json"

    TLSA_RECORD=$(${getExe pkgs.openssl} x509 -in /var/lib/acme/${arcanum.domain}/cert.pem -pubkey -noout \
      | ${getExe pkgs.openssl} pkey -pubin -outform DER \
      | ${getExe pkgs.openssl} dgst -sha256 -binary \
      | ${getExe pkgs.unixtools.xxd} -p \
      | tr -d '\n')

    ${getExe pkgs.curl} -X POST "https://desec.io/api/v1/domains/${arcanum.domain}/rrsets/" \
        --header "Authorization: Token ''${DESEC_TOKEN}" \
        --header "Content-Type: application/json" --data @- <<EOF
    {
      "subname": "_25._tcp",
      "type": "TLSA",
      "ttl": 3600,
      "records": ["3 1 1 $TLSA_RECORD"]
    }
    EOF
  '';
in
{
  content = {
    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "${arcanum.personalMail}";
        server = "https://acme-v02.api.letsencrypt.org/directory";
        keyType = "ec384";
        dnsResolver = "9.9.9.9:53";
      };

      certs."${arcanum.domain}" = {
        domain = "${arcanum.domain}";
        extraDomainNames = [
          "*.${arcanum.domain}"
          "*.hsnet.${arcanum.domain}"
          "*.${arcanum.internal}"
        ];
        dnsProvider = "desec";
        environmentFile = config.sops.secrets.acme-env.path;
        # dane tlsa records
        extraLegoRenewFlags = [ "--reuse-key" ];
        reloadServices = [
          "dovecot2"
          "postfix"
          "caddy"
          "headscale"
          "headplane"
        ];
        postRun = ''
          # ${getExe tlsa-update}
          ${getExe pkgs.curl} -m 10 --retry 5 "https://health.${arcanum.domain}/ping/''${HC}"
        '';
      };
    };
    sops.secrets.acme-env = {
      sopsFile = "${arcanum.secretPath}/acme.env";
      format = "dotenv";
    };
  };
  persist.directories = singleton "/var/lib/acme";
}
