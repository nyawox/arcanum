{
  arcanum,
  pkgs,
  lib,
  ...
}:
let
  catppuccin = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/catppuccin/aerc/refs/heads/main/dist/catppuccin-mocha";
    sha256 = "14pmdmpg2q0l44d5k6z9cdp7f9lndwshkxwvy4q6warrkvylgqya";
  };
in
{
  homeConfig = {
    programs.aerc = {
      enable = true;
      stylesets.catppuccin-mocha = lib.fileContents catppuccin;
      extraConfig = {
        # i'm not storing credentials there anyway
        general.unsafe-accounts-conf = true;
        filters = {
          "text/html" =
            "${lib.getExe pkgs.pandoc} -f html -t plain | ${pkgs.aerc}/libexec/aerc/filters/colorize";
          "text/plain" = "${pkgs.aerc}/libexec/aerc/filters/colorize";
          "message/delivery-status" = "${pkgs.aerc}/libexec/aerc/filters/colorize";
          "message/rfc822" = "${pkgs.aerc}/libexec/aerc/filters/colorize";
        };
        ui = {
          styleset-name = "catppuccin-mocha";
          border-char-vertical = "│";
          border-char-horizontal = "─";
        };
      };
    };
    accounts.email = {
      maildirBasePath = ".local/share/mail";
      accounts = {
        "${arcanum.domain}" = {
          address = "${arcanum.personalMail}";
          userName = "${arcanum.personalMail}";
          realName = "${arcanum.personalMail}";
          primary = true;
          passwordCommand = "${pkgs.coreutils}/bin/cat ${arcanum.homeCfg.sops.secrets.mail-pwd1.path}";
          aliases = [
            "postmaster@${arcanum.domain}"
            "abuse@${arcanum.domain}"
            "contact@${arcanum.domain}"
            "personal@${arcanum.domain}"
            "me@${arcanum.domain}"
            "${arcanum.personalMail2}"
            "${arcanum.personalMail3}"
          ];
          imap = {
            host = "mail.${arcanum.domain}";
            port = 993;
          };
          smtp = {
            host = "mail.${arcanum.domain}";
            port = 587;
            tls.useStartTls = true;
          };
          aerc.enable = true;
        };
      };
    };
  };
  userPersist.directories = lib.singleton ".local/share/mail";
}
