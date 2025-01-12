{ self, ... }:
{
  flake = {
    deployment =
      let
        cfgs = builtins.listToAttrs (
          map (host: {
            name = host;
            value = self.nixosConfigurations.${host}.config;
          }) (builtins.attrNames self.nixosConfigurations)
        );

        hosts = builtins.filter (host: cfgs.${host}.arcanum.deploy) (builtins.attrNames cfgs);
      in
      builtins.listToAttrs (
        map (name: {
          inherit name;
          value =
            let
              cfg = cfgs.${name};
            in
            {
              hostname = name;
              inherit (cfg.arcanum) username;
              target = "${name}.${cfg.modules.networking.wireguard.interface}.${cfg.arcanum.domain}";
              port = 22420;
              retry = {
                max_attempts = 5;
                initial_delay = 5;
                max_delay = 30;
              };
            };
        }) hosts
      );
  };
}
