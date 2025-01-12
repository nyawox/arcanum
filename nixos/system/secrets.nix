{
  cfg,
  config,
  lib,
  pkgs,
  inputs,
  arcanum,
  hostname,
  ...
}:
with lib;
{
  imports = [ inputs.sops-nix.nixosModules.sops ];
  options.enablePassword = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Enable password from secrets
    '';
  };
  content = {
    sops = {
      defaultSopsFile = "/persist/dotfiles/secrets/secrets.yaml"; # non existent path
      #https://github.com/Mic92/sops-nix/issues/167
      gnupg.sshKeyPaths = [ ];
      # This will automatically import SSH keys as age keys
      # Don't forget to copy key there
      age.sshKeyPaths = singleton "/persist/etc/ssh/id_ed25519_age";
      secrets.userpassword = mkIf cfg.enablePassword {
        neededForUsers = true;
        sopsFile = "${arcanum.secretPath}/${hostname}-userpassword.yaml";
      };
    };
    users.users."${arcanum.username}" = mkIf cfg.enablePassword {
      hashedPasswordFile = config.sops.secrets.userpassword.path;
      password = mkForce null;
    };
    users.users."root".hashedPassword = mkIf cfg.enablePassword "*";
    systemd.enableEmergencyMode = mkIf cfg.enablePassword false; # this makes no sense with root password disabled
    arcanum.ignoredWarnings = [
      "The user '${arcanum.username}' has multiple of the options\n`hashedPassword`, `password`, `hashedPasswordFile`, `initialPassword`\n& `initialHashedPassword` set to a non-null value.\nThe options silently discard others by the order of precedence\ngiven above which can lead to surprising results. To resolve this warning,\nset at most one of the options above to a non-`null` value.\n"
      "The user 'root' has multiple of the options\n`hashedPassword`, `password`, `hashedPasswordFile`, `initialPassword`\n& `initialHashedPassword` set to a non-null value.\nThe options silently discard others by the order of precedence\ngiven above which can lead to surprising results. To resolve this warning,\nset at most one of the options above to a non-`null` value.\n"
    ];
    environment.systemPackages = singleton pkgs.sops;
  };
  persist.files = [
    "/etc/ssh/id_ed25519_age"
    "/etc/ssh/id_ed25519_age.pub"
  ];
}
