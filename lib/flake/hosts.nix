{
  self,
  inputs,
  stateVersion,
  withSystem,
  ...
}:
let
  extModules = [
    inputs.home-manager.nixosModules.home-manager
    inputs.nixtendo-switch.nixosModules.nixtendo-switch
    inputs.psilocybin.nixosModules.psilocybin
    inputs.nur.modules.nixos.default
  ];

  mkModulesLib =
    {
      pkgs,
      system,
      hostname,
      platform,
    }:
    import ./modules.nix {
      inherit
        self
        inputs
        hostname
        platform
        stateVersion
        system
        pkgs
        ;
      inherit (pkgs) lib;
    };

  getModules =
    args:
    let
      modulesLib = mkModulesLib args;
    in
    {
      nixosModules = modulesLib.processModules ../../nixos;
      hostModules = modulesLib.processHostModules;
    };

  mkHost =
    {
      hostname,
      username,
      platform,
      extraModules ? [ ],
      hostConfig,
    }:
    withSystem platform (
      { pkgs, system, ... }:
      let
        mods = getModules {
          inherit
            pkgs
            system
            hostname
            platform
            ;
        };
      in
      inputs.nixpkgs.lib.nixosSystem {
        inherit pkgs system;
        specialArgs = {
          inherit
            self
            inputs
            hostname
            platform
            stateVersion
            ;
        };
        modules =
          extModules
          ++ [
            ../modules
            (
              { specialArgs, ... }:
              {
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  extraSpecialArgs = specialArgs;
                  backupFileExtension = "bak";
                  verbose = true;
                  users.${username} = { };
                  sharedModules = [
                    {
                      home.stateVersion = "${stateVersion}";
                      systemd.user.startServices = "sd-switch";
                    }
                    ../../home/${hostname}
                  ];
                };
              }
              // (hostConfig {
                inherit pkgs;
                inherit (pkgs) lib;
              })
            )
          ]
          ++ extraModules
          ++ mods.nixosModules
          ++ mods.hostModules;
      }
    );
in
{
  nixos =
    {
      hostname,
      username ? "nyaa",
      secrets ? false,
      home-secrets ? false,
      deploy ? true,
      platform ? "x86_64-linux",
    }:
    mkHost {
      inherit
        hostname
        username
        platform
        ;
      extraModules = [ ../../var/global.nix ];
      hostConfig =
        { lib, ... }:
        {
          arcanum = {
            inherit username deploy;
          };
          networking.hostName = hostname;
          nixpkgs.hostPlatform = platform;
          modules.system.secrets = lib.mkIf secrets {
            enable = true;
            enablePassword = true;
          };
          modules.system.home-secrets.enable = lib.mkIf home-secrets true;
        };
    };

  iso =
    { platform }:
    mkHost rec {
      hostname = "nixos-installer";
      username = "nixos";
      inherit platform;
      extraModules = [
        "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
      ];
      hostConfig = _: {
        arcanum = {
          inherit username;
          deploy = false;
        };
        nixpkgs.hostPlatform = platform;
      };
    };
}
