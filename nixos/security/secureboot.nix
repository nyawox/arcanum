{
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];
  content = {
    boot = {
      bootspec.enable = true;
      # Lanzaboote currently replaces the systemd-boot module.
      # This setting is usually set to true in configuration.nix
      # generated at installation time. So we force it to false
      # for now.
      loader.systemd-boot.enable = mkForce false;
      #loader.systemd-boot.enable = true;

      lanzaboote = {
        enable = true;
        # enrollKeys = true;
        configurationLimit = mkDefault 15;
        pkiBundle = "/persist/var/lib/sbctl";
      };
    };

    # For debugging and troubleshooting Secure Boot.
    environment.systemPackages = singleton pkgs.sbctl;
  };
  persist.directories = singleton "/var/lib/sbctl";
}
