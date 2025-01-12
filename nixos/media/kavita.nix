# keeping it to reference later
{
  config,
  lib,
  arcanum,
  hostname,
  pkgs,
  ...
}:
with lib;
{
  content = {
    sops.secrets.kavita-token = {
      owner = "kavita";
      group = "kavita";
      format = "yaml";
      sopsFile = "${arcanum.secretPath}/kavita-secrets.yaml";
      restartUnits = [ "kavita.service" ];
    };
    services.kavita = {
      enable = true;
      settings = {
        IpAddresses = "0.0.0.0,::";
        Port = 5004;
      };
      tokenKeyFile = config.sops.secrets.kavita-token.path;
    };
    systemd = {
      services.kavita.after = [ "var-lib-kavita.mount" ];
      tmpfiles.rules =
        let
          upstreamRepo = pkgs.fetchFromGitHub {
            owner = "Kareadita";
            repo = "Kavita";
            rev = "6ae9cbf4aa9be398d096547e1e024198c1df6bec";
            hash = "sha256-yDqsbFurcRZVNbgJFMfOGyeXd/Rv9Xgir2GSil46hYE=";
          };
        in
        [
          "d /persist/var/lib/kavita/config 0750 kavita kavita -" # kavita fails to start
          "d /persist/var/lib/kavita/library 0750 kavita kavita -" # shared book library
          "C /persist/var/lib/kavita/EmailTemplates 0750 kavita kavita - ${upstreamRepo}/API/EmailTemplates"
        ];
    };
    services.samba = {
      enable = true;
      settings = {
        kavita = {
          path = "/var/lib/kavita/library";
          writable = true;
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "yes";
          "force user" = "kavita";
          "force group" = "kavita";
          "create mask" = "0664";
          "directory mask" = "0775";
        };
        global = {
          workgroup = "WORKGROUP";
          "server string" = "${hostname}";
          "netbios name" = "${hostname}";
          "hosts allow" = "100.64.0.0/10 10.0.0.0/8 127.0.0.1 localhost ::1";
          "hosts deny" = "0.0.0.0/0";
          "guest account" = "nobody";
          "map to guest" = "Bad User";
          "mangled names" = "no";
          "fruit:aapl" = "yes";
          "fruit:nfs_aces" = "no";
          "fruit:metadata" = "stream";
          "fruit:model" = "MacSamba";
          "fruit:posix_rename" = "yes";
          "fruit:veto_appledouble" = "no";
          "fruit:wipe_intentionally_left_blank_rfork" = "yes";
          "fruit:delete_empty_adfiles" = "yes";
          "vfs objects" = "catia fruit streams_xattr acl_xattr";
          "veto files" = "/._*/.DS_Store/";
        };
      };
    };
    arcanum.sysUsers = [ "kavita" ];
  };
  persist.directories = singleton {
    directory = "/var/lib/kavita";
    user = "kavita";
    group = "kavita";
    mode = "750";
  };
}
