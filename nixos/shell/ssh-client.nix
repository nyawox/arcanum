{
  lib,
  pkgs,
  arcanum,
  ...
}:
with lib;
let
  hostKeys = {
    localhoax = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAuigCR5jpN9F1GjDygcXSvjwvQ4UREecVrj7BuqQMSx";
      endpoint = "${arcanum.localhoax-ip}";
    };
    localpost = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAtcE6jROh15Whm1yEtjGTum2MUc/iKXt4OdISEV8ewb";
      endpoint = "${arcanum.localpost-ip4}";
    };
    lokalhost = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOM86kWF+pZ3JnXTxktD7L4uym+Dbr4g0vEbdedj+vXz";
      endpoint = "${arcanum.lokalhost-ip}";
    };
    localtoast = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHpa7Qp3XqLvjgDMst7JKqPXYD6AFR9qGwOpNcFpm9TA";
      endpoint = "${arcanum.localtoast-ip4}";
    };
    localghost = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBDGm5mHr0P6BNKwDMsEl8wbK7oQ+MBFkWadsY40IVWu";
      endpoint = "${arcanum.localghost-ip}";
    };
    localcoast = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAIFrq2/a9ibLGJUctaZajgopO5BlgcU0sOt1tmbK2Yh";
      endpoint = "${arcanum.localcoast-ip}";
    };
    localhostage = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG8l2eWBqaawMtImuwJDTc0+xXTIPC73CkHwz/ndSINf";
      endpoint = "${arcanum.localhostage-ip4}";
    };
    lolcathost = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPgPZSPprj4B9RrVPh4+GCnrcTaUiXXvqbaoh9lWwaF9";
    };
  };

  mkLuksHost = name: data: {
    hostname = data.endpoint;
    user = "root";
    port = 42420;
    identitiesOnly = true;
    identityFile = [
      "${pkgs.writeText "${name}.${arcanum.internal}" data.key}"
    ];
    extraOptions = {
      RequestTTY = "force";
      RemoteCommand = "systemctl default";
      ConnectionAttempts = "30";
    };
  };

  mkHosts = name: data: {
    hostname = "${name}.${arcanum.internal}";
    user = "${arcanum.username}";
    port = 22420;
    forwardAgent = true; # will be always prompted anyway
    identitiesOnly = true;
    identityFile = [
      "${pkgs.writeText "${name}.${arcanum.internal}" data.key}"
    ];
  };

  luksHosts = lib.filterAttrs (_: v: v ? endpoint) hostKeys;
  luksConfigs = lib.mapAttrs' (
    name: data: nameValuePair "${name}luks" (mkLuksHost name data)
  ) luksHosts;

  # Generate regular hosts for all hosts
  hostConfigs = lib.mapAttrs' (
    name: data: nameValuePair "${name}.${arcanum.internal}" (mkHosts name data)
  ) hostKeys;

  otherHosts = {
    router = {
      hostname = "192.168.0.160";
      user = "root";
    };
    routerhallway = {
      hostname = "192.168.0.155";
      user = "root";
    };
    ChidamaGakuen = {
      hostname = "192.168.0.194";
      user = "hiyori";
      port = 22;
      checkHostIP = false;
    };
    "git.${arcanum.domain}" = {
      hostname = "localpost.${arcanum.internal}";
      user = "${arcanum.username}";
      port = 3024;
      identitiesOnly = true;
      identityFile = [
        "${pkgs.writeText "forgejo-localpost" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICYzAbfLJ1PCXf8g8TXwSAzxva+M2YSoE8fb0TE9nER"}"
      ];
    };
    "codeberg.org" = {
      hostname = "codeberg.org";
      identitiesOnly = true;
      identityFile = [
        "${pkgs.writeText "codeberg" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGIRZxIPRDmjZ9Wz6JqfXvAhkwYYuCjA1tzBldQCJnj0"}"
      ];
    };
    "github.com" = {
      hostname = "github.com";
      identitiesOnly = true;
      identityFile = [
        "${pkgs.writeText "github" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBBFjmUk+ksIhm8aOHUl6B48wW0aMXOe+E1S71bsVvQU"}"
      ];
    };
  };
in
{
  homeConfig.programs = {
    ssh = {
      enable = true;
      compression = true;
      controlMaster = "auto";
      extraConfig = ''
        ServerAliveInterval 15
        ServerAliveCountMax 3
        ConnectionAttempts 3
        RekeyLimit default 600
        VisualHostKey yes
        UpdateHostKeys yes
        IdentitiesOnly yes
      '';
      matchBlocks = lib.mkMerge [
        luksConfigs
        hostConfigs
        otherHosts
      ];
    };
    nushell.shellAliases.unknownssh = "ssh -o IdentitiesOnly=no";
  };
}
