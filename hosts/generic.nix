{
  pkgs,
  lib,
  self,
  inputs,
  stateVersion,
  arcanum,
  platform,
  ...
}:
with lib;
{
  config = {
    modules = {
      monitoring.prometheus-node-exporter.enable = mkDefault true;
      system = {
        disko.enable = true;
        impermanence.enable = mkForce true; # all modules are made with impermanence in mind and won't build disabled
        locale.enable = mkDefault true;
        io-sched.enable = mkDefault true;
        zram.enable = mkDefault true;
        tty.enable = mkDefault true;
        chrony.enable = mkDefault true;
      };
      security = {
        sudo-rs.enable = mkDefault true;
        pam = {
          enable = mkDefault true;
          rssh = mkDefault true;
        };
        usbguard.enable = mkDefault true;
        hardening.enable = true;
      };
      services = {
        ssh.enable = mkDefault true;
        eternal-terminal.enable = mkDefault true;
      };
      networking = {
        avahi.enable = mkDefault true;
        tailscale.enable = mkDefault true;
        wireguard.enable = mkDefault true;
        networkd.enable = mkDefault true;
        resolved.enable = mkDefault true;
      };
      shell = {
        helix.enable = mkIf (platform == "x86_64-linux") (mkDefault true); # avoid manual building for aarch64 hosts
        nushell.enable = mkDefault true;
        bottom.enable = mkDefault true;
        fastfetch.enable = mkDefault true;
        git.enable = mkDefault true;
        nix.enable = mkDefault true;
      };
    };

    boot = {
      loader = {
        # Use the systemd-boot EFI boot loader.
        systemd-boot.enable = mkDefault true;
        systemd-boot.configurationLimit = mkDefault 15;
        efi.canTouchEfiVariables = mkDefault false;
        timeout = mkDefault 0;
      };

      blacklistedKernelModules = [ "ip_tables" ]; # don't need it. i already rely on nftables too much
      kernelPackages = mkDefault pkgs.linuxPackages_latest;
      kernelModules = [ "lkrg" ];
      kernelParams = [ "libahci.ignore_sss=1" ];

      initrd.systemd.enable = mkDefault true;

      consoleLogLevel = mkDefault 7;
    };

    security = {
      forcePageTableIsolation = mkDefault true;
      virtualisation.flushL1DataCache = mkDefault "always";
      auditd.enable = true;
    };

    hardware.enableRedistributableFirmware = mkDefault true;

    environment = {
      memoryAllocator.provider = mkDefault "scudo";
      variables.SCUDO_OPTIONS = mkDefault "ZeroContents=1";
      variables.EDITOR = "hx";
      systemPackages = with pkgs; [
        helix
        git
        wget
        # backup
        restic
      ];
    };
    programs = {
      command-not-found.dbPath = inputs.programsdb.packages.${pkgs.system}.programs-sqlite;

      # Otherwise home-manager will fail https://github.com/nix-community/home-manager/issues/3113
      dconf.enable = mkForce true;

      # Some programs need SUID wrappers, can be configured further or are
      # started in user sessions.
      mtr.enable = true;
    };

    networking = {
      nftables.enable = true;
      firewall.allowPing = mkForce false;
    };

    users = {
      users = {
        "${arcanum.username}" = {
          group = "users";
          isNormalUser = true;
          description = "nyan";
          linger = true;
          # Default password is alpinerickroll
          password = mkDefault "alpinerickroll";
          extraGroups = [
            "wheel"
            "audio"
            "input"
            "video"
            "netdev"
            "uinput"
          ];
          subUidRanges = [
            {
              count = 2147483647;
              startUid = 2147483648;
            }
          ];
          subGidRanges = [
            {
              count = 2147483647;
              startGid = 2147483648;
            }
          ];
        };
        # set root password to null
        root.password = mkDefault null;
      };
      groups.wheel = {
        members = [
          "${arcanum.username}"
          "root"
        ];
      };
      mutableUsers = false;

      defaultUserShell = pkgs.nushell;
    };
    psilocybin = {
      enable = mkDefault true;
      package = mkDefault pkgs.kanata;
    };

    services.dbus = {
      enable = true;
      implementation = "broker";
    };

    # Boot faster
    systemd.services.systemd-udev-settle.enable = false;

    system = {
      inherit stateVersion;
      # Include git commit hash on boot label
      configurationRevision = mkIf (self ? rev) self.rev;
      # https://github.com/nushell/nu_scripts/blob/main/modules/nix/activation-script
      activationScripts.diff = ''
        if [[ -e /run/current-system ]]; then
          ${pkgs.nushell}/bin/nu -c "let diff_closure = (${pkgs.nix}/bin/nix store diff-closures /run/current-system '$systemConfig'); let table = (\$diff_closure | lines | where \$it =~ KiB | where \$it =~ → | parse -r '^(?<Package>\S+): (?<Old>[^,]+)(?:.*) → (?<New>[^,]+)(?:.*), (?<DiffBin>.*)$' | insert Diff { get DiffBin | ansi strip | into filesize } | sort-by -r Diff | reject DiffBin); if (\$table | get Diff | is-not-empty) { print \"\"; \$table | append [[Package Old New Diff]; [\"\" \"\" \"\" \"\"]] | append [[Package Old New Diff]; [\"\" \"\" \"Total:\" (\$table | get Diff | math sum) ]] | print; print \"\" }"
        fi
      '';
    };
  };
}
