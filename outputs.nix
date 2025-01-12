{ self, ... }@inputs:
inputs.flake-parts.lib.mkFlake { inherit inputs; } (
  { withSystem, ... }:
  {
    systems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
    ];
    imports = [
      inputs.devshell.flakeModule
      inputs.treefmt-nix.flakeModule
      inputs.pkgs-by-name-for-flake-parts.flakeModule
      inputs.flake-parts.flakeModules.easyOverlay
      ./deploy.nix
      ./per-system.nix
    ];
    flake =
      let
        inherit (self) outputs;
        # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
        stateVersion = "23.11";
        arcanum = import ./lib/flake {
          inherit
            self
            inputs
            outputs
            stateVersion
            withSystem
            ;
        };
      in
      {
        nixosConfigurations = with arcanum; {
          lolcathost = nixos {
            hostname = "lolcathost";
            secrets = true;
            home-secrets = true;
          };
          localtoast = nixos {
            hostname = "localtoast";
            secrets = true;
          };
          localpost = nixos {
            hostname = "localpost";
            platform = "aarch64-linux";
            secrets = true;
          };
          lokalhost = nixos {
            hostname = "lokalhost";
            secrets = true;
          };
          localhoax = nixos {
            hostname = "localhoax";
            platform = "aarch64-linux";
            secrets = true;
          };
          localghost = nixos {
            hostname = "localghost";
            secrets = true;
          };
          localcoast = nixos {
            hostname = "localcoast";
            secrets = true;
          };
          localhostage = nixos {
            hostname = "localhostage";
            secrets = true;
          };
          iso = iso { platform = "x86_64-linux"; };
          isoarm = iso { platform = "aarch64-linux"; };
        };
      };
  }
)
