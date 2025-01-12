{
  lib,
  config,
  arcanum,
  inputs,
  ...
}:
with lib;
{
  imports = [ inputs.mailserver.nixosModules.mailserver ];
  content = {
    sops.secrets = {
      mailserver-personal = {
        sopsFile = "${arcanum.secretPath}/mailserver-secrets.yaml";
        format = "yaml";
        restartUnits = [
          "postfix.serivce"
          "dovecot2.service"
        ];
      };
      mailserver-git = {
        sopsFile = "${arcanum.secretPath}/mailserver-secrets.yaml";
        format = "yaml";
        restartUnits = [
          "postfix.serivce"
          "dovecot2.service"
        ];
      };
      mailserver-notifications = {
        sopsFile = "${arcanum.secretPath}/mailserver-secrets.yaml";
        format = "yaml";
        restartUnits = [
          "postfix.serivce"
          "dovecot2.service"
        ];
      };
      mailserver-noreply = {
        sopsFile = "${arcanum.secretPath}/mailserver-secrets.yaml";
        format = "yaml";
        restartUnits = [
          "postfix.serivce"
          "dovecot2.service"
        ];
      };
      mailserver-spam = {
        sopsFile = "${arcanum.secretPath}/mailserver-secrets.yaml";
        format = "yaml";
        restartUnits = [
          "postfix.serivce"
          "dovecot2.service"
        ];
      };
      mailserver-info = {
        sopsFile = "${arcanum.secretPath}/mailserver-secrets.yaml";
        format = "yaml";
        restartUnits = [
          "postfix.serivce"
          "dovecot2.service"
        ];
      };
      mailserver-privkey = {
        sopsFile = "${arcanum.secretPath}/mailserver-secrets.yaml";
        format = "yaml";
        restartUnits = [
          "postfix.serivce"
          "dovecot2.service"
        ];
      };
      mailserver-pubkey = {
        sopsFile = "${arcanum.secretPath}/mailserver-secrets.yaml";
        format = "yaml";
        restartUnits = [
          "postfix.serivce"
          "dovecot2.service"
        ];
      };
      radicale-htpasswd = {
        sopsFile = "${arcanum.secretPath}/mailserver-secrets.yaml";
        owner = "radicale";
        group = "radicale";
        format = "yaml";
        restartUnits = [ "radicale.serivce" ];
      };
    };
    environment.memoryAllocator.provider = "libc"; # dovecot2 don't work with scudo (or other hardened) mallocs
    modules.monitoring.promtail.enable = true;
    arcanum.sysUsers = [ "postfix" ];
    users.users.promtail.extraGroups = singleton "postfix";
    services = {
      # clamav.daemon.settings.ConcurrentDatabaseReload = false;
      postfix = {
        config = {
          # i don't need tls1.1
          smtpd_tls_protocols = mkForce "TLSv1.3, TLSv1.2, !TLSv1.1, !TLSv1, !SSLv2, !SSLv3";
          smtp_tls_protocols = mkForce "TLSv1.3, TLSv1.2, !TLSv1.1, !TLSv1, !SSLv2, !SSLv3";
          smtpd_tls_mandatory_protocols = mkForce "TLSv1.3, TLSv1.2, !TLSv1.1, !TLSv1, !SSLv2, !SSLv3";
          smtp_tls_mandatory_protocols = mkForce "TLSv1.3, TLSv1.2, !TLSv1.1, !TLSv1, !SSLv2, !SSLv3";
          smtp_tls_security_level = "dane";
          # not sure if it's working
          smtp_dns_support_level = "dnssec";
          # log file for promtail
          maillog_file = "/var/log/mail/postfix.log";
          maillog_file_permissions = 640;
        };
        masterConfig.postlog = {
          type = "unix-dgram";
          private = false;
          chroot = false;
          privileged = false;
          maxproc = 1;
          command = "postlogd";
        };
      };
      logrotate.settings.postfix = {
        files = "/var/log/mail/postfix.log";
        create = "0640 postfix postfix";
        rotate = 1;
        frequency = "daily";
        compress = true;
        missingok = true;
        notifempty = true;
      };
      promtail.configuration.scrape_configs = singleton {
        job_name = "mail";
        static_configs = singleton {
          targets = singleton "localhost";
          labels = {
            job = "mail";
            host_id = "mail.${arcanum.domain}";
            __path__ = "/var/log/mail/postfix.log";
          };
        };
      };
      dovecot2 = {
        mailPlugins = {
          globally.enable = [
            "zlib" # mail_compress in 2.4
            "mail_crypt"
          ];
          perProtocol.imap.enable = [ "imap_zlib" ];
        };
        pluginSettings = {
          zlib_save = "lz4";
          # update to EdDSA key after 2.4 release
          mail_crypt_global_private_key = "<${config.sops.secrets.mailserver-privkey.path}";
          mail_crypt_global_public_key = "<${config.sops.secrets.mailserver-pubkey.path}";
          mail_crypt_save_version = "2";
        };
      };
      radicale = {
        enable = true;
        settings = {
          server.hosts = [
            "0.0.0.0:8642"
            "[::]:8642"
          ];
          auth = {
            type = "htpasswd";
            htpasswd_filename = config.sops.secrets.radicale-htpasswd.path;
            htpasswd_encryption = "bcrypt";
          };
          storage.filesystem_folder = "/var/lib/radicale";
        };
      };
    };
    systemd.tmpfiles.settings."postfix-log"."/var/log/mail/postfix.log".Z = {
      mode = "0640";
      user = "postfix";
      group = "postfix";
    };
    mailserver = {
      enable = true;
      localDnsResolver = false;
      fqdn = "mail.${arcanum.domain}";
      domains = [ "${arcanum.domain}" ];
      loginAccounts = {
        # mkpasswd -sm bcrypt
        "${arcanum.personalMail}" = {
          hashedPasswordFile = config.sops.secrets.mailserver-personal.path;
          aliases = [
            "postmaster@${arcanum.domain}"
            "abuse@${arcanum.domain}"
            "contact@${arcanum.domain}"
            "personal@${arcanum.domain}"
            "me@${arcanum.domain}"
            "${arcanum.personalMail2}"
            "${arcanum.personalMail3}"
          ];
        };
        "git@${arcanum.domain}" = {
          hashedPasswordFile = config.sops.secrets.mailserver-git.path;
        };
        "info@${arcanum.domain}" = {
          hashedPasswordFile = config.sops.secrets.mailserver-info.path;
        };
        "noreply@${arcanum.domain}" = {
          hashedPasswordFile = config.sops.secrets.mailserver-noreply.path;
          sendOnly = true;
        };
        "notifications@${arcanum.domain}" = {
          hashedPasswordFile = config.sops.secrets.mailserver-notifications.path;
          sendOnly = true;
        };
        "spam@${arcanum.domain}" = {
          aliases = [ "ilobe@${arcanum.domain}" ];
          hashedPasswordFile = config.sops.secrets.mailserver-spam.path;
        };
      };
      certificateScheme = "manual";
      keyFile = "/var/lib/acme/${arcanum.domain}/key.pem";
      certificateFile = "/var/lib/acme/${arcanum.domain}/cert.pem";
      recipientDelimiter = "_";
      mailDirectory = "/var/lib/vmail";
      indexDir = "/var/lib/dovecot/indices";
      dkimKeyDirectory = "/var/lib/dkim";
      sieveDirectory = "/var/lib/sieve";
      dmarcReporting = {
        enable = true;
        inherit (arcanum) domain;
        organizationName = "${arcanum.domain}";
      };
      useFsLayout = true;
      virusScanning = false;
      fullTextSearch = {
        enable = true;
        autoIndex = true;
        indexAttachments = true;
        enforced = "body";
      };
    };
    modules.backup.restic = {
      enable = true;
      list = [
        {
          name = "radicale";
          path = "/var/lib/radicale";
        }
      ];
    };
  };
  persist.directories = [
    "${config.mailserver.mailDirectory}"
    "${config.mailserver.indexDir}"
    {
      directory = "${config.mailserver.dkimKeyDirectory}";
      inherit (config.services.opendkim) user;
      inherit (config.services.opendkim) group;
    }
    "${config.mailserver.sieveDirectory}"
    "/var/log/mail"
    {
      directory = "${config.services.radicale.settings.storage.filesystem_folder}";
      user = "radicale";
      group = "radicale";
    }
    # {
    #   directory = "/var/lib/clamav";
    #   user = "clamav";
    #   group = "clamav";
    # }
  ];
}
