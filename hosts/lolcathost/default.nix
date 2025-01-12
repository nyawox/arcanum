{
  config,
  lib,
  arcanum,
  inputs,
  pkgs,
  ...
}:
with lib;
{
  imports = [ inputs.madness.nixosModules.madness ];
  modules = {
    system = {
      disko.disk.device = "/dev/nvme0n1";
      wifi.enable = true;
      bluetooth.enable = true;
      udisks2.enable = true;
      gvfs.enable = true;
      iphone-fastcharge.enable = true;
      amdgpu = {
        enable = true;
        modeSet = true;
      };
      nvidia = {
        enable = true;
        modeSet = true;
        prime = true;
      };
    };
    servers = {
      ollama = {
        enable = true;
        container = false;
      };
      minecraft.enable = true;
      snapcast.enable = true;
    };
    security = {
      kanidm-client.enable = true;
      usbguard = {
        notifier = true;
        # allow-at-boot = true; # enable this to generate usbguard rules the first time
      };
      secureboot.enable = true;
      tang.enable = true;
      remoteunlock.enable = true;
      crowdsec-lolcathost.enable = true;
      goldwarden = {
        enable = true;
        # biometrics = true;
        # disabled until ssh-key item-type is supported
        # https://github.com/quexten/goldwarden/issues/272
        # sshAgent = true;
      };
      bitwarden-desktop = {
        enable = true;
        biometrics = true;
        sshAgent = true;
      };
      tpm2.enable = true;
      hardening = {
        desktop = {
          allow-unprivileged-userns = true; # used in bubblewrap
          allow-multilib = true;
        };
        compatibility.allow-binfmt-misc = true; # required for aarch64 compilation on nix
        performance.allow-smt = true; # enable smt to increase performance
      };
    };
    networking = {
      tailscale = {
        notifier = true;
        tags = [ "tag:admin-desktops" ];
      };
      wireguard = {
        enable = true;
        exporter = true;
      };
      tor.enable = true;
      v2ray.enable = true;
    };
    services = {
      flatpak = {
        enable = true;
        fonts = true;
      };
      airplay.enable = true;
      adb-server.enable = true;
    };
    desktop = {
      niri = {
        enable = true;
        default = true;
      };
      firefox.enable = true;
      piper.enable = true;
      headsetcontrol.enable = true;
      gaming.enable = true;
      pipewire.enable = true;
      plymouth.enable = true;
      mpv.enable = true;
      obsidian.enable = true;
      firejail = {
        enable = true;
        tor-browser = true;
        signal-desktop = true;
        vesktop = true;
        vivaldi = true;
        netflix = true;
        uget = true;
      };
    };
    shell = {
      bat.enable = true;
      helix.ide = true;
      atuin.enable = true;
      ssh-client.enable = true;
      mail-client.enable = true;
    };
    virtualisation = {
      windows = {
        enable = true;
        iso = {
          enable = true;
          shrink = true;
        };
        gpuPassthrough = {
          enable = true;
          # iommu group 13
          nvidia.gpuid = "pci_0000_01_00_0";
          nvidia.audioid = "pci_0000_01_00_1";
        };
      };
      macos = {
        enable = true;
        gpuPassthrough = {
          enable = true;
          # iommu group 17
          amd.gpuid = "pci_0000_0d_00_0";
        };
      };
      mac922.enable = true;
    };
  };

  sops.secrets = {
    "switch" = {
      sopsFile = ../../secrets/switch.env;
      format = "dotenv";
      owner = config.users.users.${arcanum.username}.name;
      inherit (config.users.users.${arcanum.username}) group;
      restartUnits = [ "switch-presence.service" ];
    };
    hdd-crypto.sopsFile = ../../secrets/hdd-crypto.yaml;
    builderKey = {
      sopsFile = ../../secrets/builder-key.yaml;
      format = "yaml";
    };
  };

  networking = {
    interfaces.enp9s0.useDHCP = lib.mkDefault true; # not sure if it's still necessary
    firewall.extraInputRules = # py
      ''
        # avahi
        iifname "enp9s0" udp dport 5353 accept

        # localhoax open-webui ollama
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.1/32 tcp dport { 11434 } accept
        # 11434 ollama

        # lolcathost
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.3/32 tcp dport { 22420, 2022 } accept
        # loopback ssh, required to deploy
        # 2022 et

        # localpost
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.2/32 tcp dport { 9100, 9584, 6764 } accept
        # allow prometheus to access node_exporter 9100 and wireguard 9584, crowdsec 6764
      '';
  };

  madness.enable = true;
  services = {
    # github:nyawox/nixtendo-switch
    switch-boot.enable = true;
    switch-presence = {
      enable = true;
      environmentFile = config.sops.secrets.switch.path;
    };
    kmscon.enable = lib.mkForce false;
    irqbalance.enable = true;
    tumbler.enable = true;
    ratbagd.enable = true;
    udev.extraRules =
      # rules
      ''
        # sysdvr
        SUBSYSTEM=="usb", ATTRS{idVendor}=="18d1", ATTRS{idProduct}=="4ee0", MODE="0666"
        # create a separate symlink for touchpad, so i can passthrough to vm (sadly couldn't make work)
        SUBSYSTEM=="input", ATTRS{name}=="Wacom Bamboo 16FG 4x5 Finger", KERNEL=="event*", SYMLINK+="touchypaddy"
      '';

    pipewire.extraConfig = {
      pipewire."92-low-latency".context.properties.default.clock = {
        rate = 48000;
        quantum = 80;
        min-quantum = 80;
        max-quantum = 80;
      };
      pipewire-pulse."92-low-latency" = {
        context.modules = singleton {
          name = "libpipewire-module-protocol-pulse";
          args.pulse = {
            min.req = "80/48000";
            default.req = "80/48000";
            max.req = "80/48000";
            min.quantum = "80/48000";
            max.quantum = "80/48000";
          };
        };
        stream.properties = {
          node.latency = "80/48000";
          resample.quality = 1;
        };
      };
      # route from line in to line out, mainly for kvm switcher, and vm guests
      # pipewire."10-loopback-line_in" = {
      #   "context.modules" = singleton {
      #     name = "libpipewire-module-loopback";
      #     args = {
      #       "capture.props" = {
      #         "audio.position" = [
      #           "FL"
      #           "FR"
      #         ];
      #         "node.name" = "Line In";
      #         "node.target" = "alsa_input.pci-0000_0e_00.3.analog-stereo";
      #       };
      #       "playback.props" = {
      #         "audio.position" = [
      #           "FL"
      #           "FR"
      #         ];
      #         "node.name" = "Loopback-line_in";
      #         "media.class" = "Stream/Output/Audio";
      #         "monitor.channel-volumes" = true;
      #       };
      #     };
      # };
    };
  };

  # /run/kanata-psilocybin/psilocybin
  psilocybin.devices = [ "/dev/input/by-id/usb-Topre_Corporation_HHKB_Professional-event-kbd" ];

  gtk.iconCache.enable = true;

  programs.gnome-disks.enable = true;

  boot = {
    binfmt.emulatedSystems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-windows"
      "i686-windows"
    ];
    loader.efi.canTouchEfiVariables = true;
    loader.efi.efiSysMountPoint = "/boot";
    # patch kernel to allow to specify boot vga device
    kernelPatches = [
      {
        name = "vgaarb-bootdev";
        patch = pkgs.fetchurl {
          url = "lore.kernel.org/lkml/8498ea9f-2ba9-b5da-7dc4-1588363f1b62@absolutedigital.net/t.mbox.gz";
          sha256 = "086gifmmnrvl3qdmj9a14zr19mw38j8c8kl3glcj08qd114yxnal";
        };
      }
    ];
    # default to amd gpu, then fallback if not avaliable
    kernelParams = [
      "vgaarb.bootdev=0d:00.0"
    ];

    initrd = {
      verbose = false;
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "sd_mod"
      ];
    };
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";
  };

  hardware = {
    cpu.amd.updateMicrocode = true;
    # make sure to connect on xhci port, it's broken rn on usb 2.0
    xone.enable = true;
  };

  nix = {
    buildMachines = [
      {
        hostName = "localhoax-builder";
        system = "aarch64-linux";
        protocol = "ssh-ng";
        maxJobs = 2;
        speedFactor = 10; # the higher the faster
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
      }
    ];
    distributedBuilds = true;
    settings = {
      builders-use-substitutes = true;
    };
  };
  programs.ssh.extraConfig = ''
    Host localhoax-builder
      HostName localhoax.${arcanum.internal}
      Port 22420
      IdentitiesOnly yes
      IdentityFile ${config.sops.secrets.builderKey.path}
      User builder
  '';

  fileSystems."/mnt/hdd".device = "/dev/mapper/hdd";
  environment = {
    # ios tweak dev
    variables.THEOS = "/home/${arcanum.username}/theos";
    # scudo causing issue when building package
    memoryAllocator.provider = "libc";
    # use crypttab for non boot required luks devices
    etc."crypttab".text = ''
      hdd /dev/disk/by-uuid/b347d514-3e34-4bb1-8a72-630176f48783 ${config.sops.secrets.hdd-crypto.path}
    '';

    persistence."/persist" = {
      directories = singleton {
        directory = "/arcanum";
        user = "${arcanum.username}";
        group = "users";
        mode = "700";
      };
      users."${arcanum.username}".directories = [
        "theos"
        ".local/share/remmina"
        ".local/share/TelegramDesktop"
        ".config/remmina"
        ".config/onlyoffice"
        ".config/calibre"
        ".wine"
      ];
    };
  };
}
