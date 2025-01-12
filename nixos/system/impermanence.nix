{
  inputs,
  arcanum,
  ...
}:
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];
  content = {
    boot.tmp.cleanOnBoot = true;
    environment.persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/tmp"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/var/lib/systemd/timesync/clock"
        "/var/lib/systemd/linger"
        "/var/lib/systemd/timers"
        # Add this globally to prevent permission issues
        {
          directory = "/var/lib/private/";
          user = "root";
          group = "root";
          mode = "700";
        }
        "/tmp"
      ];
      # files = [
      # Just an example with parent directory permissions don't enable { file = "/etc/nix/id_rsa"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
      # ];
      # TODO: migrate some of them to their respective module
      users."${arcanum.username}" = {
        directories = [
          "Downloads"
          "Music"
          "Pictures"
          "Documents"
          "Videos"
          "Projects"
          "Public"
          {
            directory = ".gnupg";
            mode = "703";
          }
          {
            directory = ".local/share/keyrings";
            mode = "706";
          }
          ".var/app"
          ".cache"
        ];
      };
    };
  };
}
