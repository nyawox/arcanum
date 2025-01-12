# Fully automated Win11 VM installation
# After rebooting the screen may turn off during the specialization phase. Just wait for it to finish, as it can take a long time
{
  cfg,
  lib,
  pkgs,
  arcanum,
  inputs,
  ...
}:
with lib;
let
  virtLib = inputs.nixvirt.lib;
  nvidia-vbios = pkgs.fetchurl {
    url = "https://archive.org/download/patched_gtx_1650_vfio/patched_nvidia.rom";
    sha256 = "0rsppbdh7kgjxv168si879b90j1rmsql96bb32f1xvb0p458p7db";
  };
in
{
  options = {
    guestName = mkOption {
      type = types.str;
      default = "win11";
    };
    iso = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
      shrink = mkOption {
        type = types.bool;
        default = false;
        description = ''
          compress the iso file. maxes out cpu usage for about 10~15 minutes
        '';
      };
    };
    gpuPassthrough = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
      nvidia = {
        gpuid = mkOption {
          type = types.str;
          default = "";
        };
        audioid = mkOption {
          type = types.str;
          default = "";
        };
      };
    };
  };
  content = {
    modules.virtualisation = {
      libvirtd.enable = mkForce true;
      windownload.enable = mkIf cfg.iso.enable true;
      nvidiahooks.enable = mkIf cfg.gpuPassthrough.enable true;
    };
    # without "d". nixvirt module
    virtualisation.libvirt.connections."qemu:///system" = {
      pools = [
        {
          active = true;
          definition = virtLib.pool.writeXML {
            name = "winstore";
            uuid = "4371142d-5a1e-470b-8a25-968ac1cdcbad";
            type = "dir";
            target = {
              path = "/home/${arcanum.username}/winstore";
            };
          };
          volumes = [
            {
              definition = virtLib.volume.writeXML {
                name = "${cfg.guestName}";
                capacity = {
                  count = 128;
                  unit = "GiB";
                };
                target = {
                  format = {
                    type = "qcow2";
                  };
                };
              };
            }
          ];
        }
      ];
      domains = [
        {
          definition =
            let
              nvramFile = "/home/${arcanum.username}/winstore/win11.nvram";
              storageFile = "/home/${arcanum.username}/winstore/win11";
              isoFile = "/home/${arcanum.username}/winstore/win11x64.iso";
            in
            virtLib.domain.writeXML {
              type = "kvm";
              name = "${cfg.guestName}";
              uuid = "8fec3116-b78b-40e8-bd04-2102fd5c758d";
              memory = {
                count = 8;
                unit = "GiB";
              };
              memoryBacking = {
                source.type = "memfd";
                access.mode = "shared"; # requirement for virtiofs
              };
              vcpu = {
                placement = "static";
                count = 16;
              };
              os = {
                type = "hvm";
                arch = "x86_64";
                machine = "q35";
                firmware = {
                  feature = [
                    {
                      enabled = false;
                      name = "enrolled-keys";
                    }
                    {
                      enabled = true;
                      name = "secure-boot";
                    }
                  ];
                };
                loader = {
                  readonly = true;
                  type = "pflash";
                  path = "${pkgs.OVMFFull.fd}/FV/OVMF_CODE.ms.fd";
                };
                nvram = {
                  template = "${pkgs.OVMFFull.fd}/FV/OVMF_VARS.ms.fd";
                  path = nvramFile;
                };
              };
              features = {
                acpi = { };
                apic = { };
                hyperv = {
                  mode = "custom";
                  relaxed = {
                    state = true;
                  };
                  vapic = {
                    state = true;
                  };
                  spinlocks = {
                    state = true;
                    retries = 8191;
                  };
                  vpindex = {
                    state = true;
                  };
                  runtime = {
                    state = true;
                  };
                  synic = {
                    state = true;
                  };
                  stimer = {
                    state = true;
                    direct = {
                      state = true;
                    };
                  };
                  reset = {
                    state = true;
                  };
                  vendor_id = {
                    state = true;
                    value = "KVM Hv";
                  };
                  frequencies = {
                    state = true;
                  };
                  reenlightenment = {
                    state = true;
                  };
                  tlbflush = {
                    state = true;
                  };
                  ipi = {
                    state = true;
                  };
                };
              };
              clock = {
                offset = "localtime";
                timer = [
                  {
                    name = "rtc";
                    tickpolicy = "catchup";
                  }
                  {
                    name = "pit";
                    tickpolicy = "delay";
                  }
                  {
                    name = "hpet";
                    present = false;
                  }

                  {
                    name = "hypervclock";
                    present = true;
                  }
                ];
              };
              pm = {
                suspend-to-mem = {
                  enabled = false;
                };
                suspend-to-disk = {
                  enabled = false;
                };
              };
              cpu = {
                mode = "host-passthrough";
                check = "none";
                migratable = true;
                topology = {
                  sockets = 1;
                  dies = 1;
                  cores = 8;
                  threads = 2;
                };
                feature = {
                  policy = "require";
                  name = "topoext";
                };
              };
              on_poweroff = "destroy";
              on_reboot = "restart";
              on_crash = "destroy";
              devices =
                let
                  pci_address = bus: slot: function: {
                    type = "pci";
                    domain = 0;
                    inherit bus slot function;
                  };
                in
                {
                  emulator = "${pkgs.qemu}/bin/qemu-system-x86_64";
                  tpm = {
                    model = "tpm-crb";
                    backend = {
                      type = "emulator";
                      version = "2.0";
                    };
                  };
                  disk = [
                    # system drive
                    {
                      type = "file";
                      device = "disk";
                      driver = {
                        name = "qemu";
                        type = "qcow2";
                        cache = "writeback";
                        discard = "unmap";
                      };
                      source = {
                        file = storageFile;
                      };
                      target = {
                        bus = "virtio";
                        dev = "vda";
                      };
                      boot = {
                        order = 1;
                      };
                    }
                    # install iso
                    {
                      type = "file";
                      device = "cdrom";
                      driver = {
                        name = "qemu";
                        type = "raw";
                      };
                      source = {
                        file = isoFile;
                        startupPolicy = "mandatory";
                      };
                      target = {
                        bus = "sata";
                        dev = "sdb";
                      };
                      boot = {
                        order = 2;
                      };
                    }
                  ];
                  filesystem = [
                    # file sharing
                    {
                      driver = {
                        type = "virtiofs";
                      };
                      source = {
                        dir = "/home/${arcanum.username}/winshare";
                      };
                      target = {
                        dir = "winshare";
                      };
                    }
                  ];
                  # evdev passthrough
                  # passing kanata directly makes hassle free
                  input =
                    let
                      mkEvdev =
                        { dev }:
                        {
                          type = "evdev";
                          source = {
                            inherit dev;
                          };
                        };
                      evdevList = [
                        "/dev/input/by-id/usb-Logitech_USB_Receiver-if02-event-mouse"
                      ];
                      mkEvdevList = map (dev: mkEvdev { inherit dev; }) evdevList;
                    in
                    [
                      {
                        type = "keyboard";
                        bus = "virtio";
                      }
                      {
                        type = "mouse";
                        bus = "virtio";
                      }
                      {
                        # "leader" device
                        type = "evdev";
                        source = {
                          dev = "/run/kanata-psilocybin/psilocybin";
                          grab = "all";
                          grabToggle = "ctrl-scrolllock";
                          repeat = true;
                        };
                      }
                    ]
                    ++ mkEvdevList;
                  # pass pipewire to guest
                  sound = {
                    model = "ich9";
                    codec = {
                      type = "micro";
                    };
                    audio = {
                      id = 1;
                    };
                  };
                  audio = {
                    id = 1;
                    type = "pipewire";
                    runtimeDir = "/run/user/1000"; # 1000 should be the default uid. couldn't find a way to avoid hardcoding
                    input = {
                      name = "qemuinput";
                      streamName = "qemuinput";
                      latency = 16384;
                    };
                    output = {
                      name = "qemuoutput";
                      streamName = "qemuoutput";
                      latency = 16384;
                    };
                  };
                  # fails to generate expected xml if i lock behind mkIf cfg.gpuPassthrough.enable
                  # all devices within the same iommu group (13) must be passed here
                  hostdev = [
                    # gpu, with patched vbios
                    {
                      mode = "subsystem";
                      type = "pci";
                      managed = true;
                      source = {
                        address = pci_address 1 0 0;
                      };
                      rom = {
                        file = "${nvidia-vbios}";
                      };
                    }
                    # gpu audio
                    {
                      mode = "subsystem";
                      type = "pci";
                      managed = true;
                      source = {
                        address = pci_address 1 0 1;
                      };
                    }
                  ];
                  interface = {
                    type = "bridge";
                    model = {
                      type = "virtio";
                    };
                    source = {
                      bridge = "virbr0";
                    };
                  };
                  # controller = [
                  #   # leaving commented out to test scsi. must explicitly set to virtio-scsi
                  #   {
                  #     type = "scsi";
                  #     index = 0;
                  #     model = "virtio-scsi";
                  #   }
                  # ];
                };
            };
        }
      ];
    };
  };
  userPersist.directories = [
    "winshare"
    "winstore"
  ];
}
