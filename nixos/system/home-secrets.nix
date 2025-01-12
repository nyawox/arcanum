{
  inputs,
  arcanum,
  ...
}:
{
  homeImports = [ inputs.sops-nix.homeManagerModules.sops ];
  homeConfig = {
    sops = {
      age.sshKeyPaths = [ "/home/${arcanum.username}/.ssh/id_ed25519_age" ];
      defaultSopsFile = "${arcanum.secretPath}/home/home-secrets.yaml";
      secrets = {
        "atuin-key" = {
          path = "/home/${arcanum.username}/.local/share/atuin/key";
        };
        "mail-pwd1" = { };
        "nix-access-tokens" = {
          sopsFile = "${arcanum.secretPath}/home/nix-access-tokens.conf";
          format = "binary";
        };
      };
    };
    nix.extraOptions = ''
      !include ${toString arcanum.homeCfg.sops.secrets.nix-access-tokens.path}
    '';
  };
}
