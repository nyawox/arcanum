# voodoohda is required to enable virtual audio, which only work when installed manually to Library/Extensions in recent versions
# to disable the relevant part of SIP
# csrutil enable --without kext
# or set csr-active-config to 03000000 in opencore
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
in
{
  options = {
    guestName = mkOption {
      type = types.str;
      default = "macos";
    };
    version = mkOption {
      type = types.str;
      default = "sequoia";
    };
    gpuPassthrough = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
      amd = {
        # there is no audio device in my amd gpu
        gpuid = mkOption {
          type = types.str;
          default = "";
        };
      };
    };
  };
  content = {
    modules.virtualisation = {
      libvirtd.enable = mkForce true;
      amdhooks.enable = mkIf cfg.gpuPassthrough.enable true;
    };
    # without "d". nixvirt module
    virtualisation.libvirt.connections."qemu:///system" = {
      pools = [
        {
          active = true;
          definition = virtLib.pool.writeXML {
            name = "macstore";
            uuid = "346bbd86-29a6-4c14-94fc-55a45cc235db";
            type = "dir";
            target = {
              path = "/home/${arcanum.username}/macstore";
            };
          };
          volumes = [
            {
              definition = virtLib.volume.writeXML {
                name = "${cfg.guestName}";
                capacity = {
                  count = 256;
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
              nvramFile = "/home/${arcanum.username}/macstore/macos.nvram";
              storageFile = "/home/${arcanum.username}/macstore/macos";
              opencoreFile = "/home/${arcanum.username}/macstore/OpenCore.img";
            in
            virtLib.domain.writeXML {
              type = "kvm";
              name = "${cfg.guestName}";
              uuid = "346bbd86-29a6-4c14-94fc-55a45cc235db";
              memory = {
                count = 16;
                unit = "GiB";
              };
              memoryBacking = {
                source.type = "memfd";
                access.mode = "shared"; # requirement for virtiofs
              };
              vcpu = {
                placement = "static";
                current = 14;
                count = 16;
              };
              vcpus = {
                vcpu = [
                  {
                    id = 0;
                    enabled = true;
                    hotpluggable = false;
                    order = 1;
                  }
                  {
                    id = 1;
                    enabled = true;
                    hotpluggable = true;
                    order = 2;
                  }
                  {
                    id = 2;
                    enabled = true;
                    hotpluggable = true;
                    order = 3;
                  }
                  {
                    id = 3;
                    enabled = true;
                    hotpluggable = true;
                    order = 4;
                  }
                  {
                    id = 4;
                    enabled = true;
                    hotpluggable = true;
                    order = 5;
                  }
                  {
                    id = 5;
                    enabled = true;
                    hotpluggable = true;
                    order = 6;
                  }
                  {
                    id = 6;
                    enabled = true;
                    hotpluggable = true;
                    order = 7;
                  }
                  {
                    id = 7;
                    enabled = true;
                    hotpluggable = true;
                    order = 8;
                  }
                  {
                    id = 8;
                    enabled = true;
                    hotpluggable = true;
                    order = 9;
                  }
                  {
                    id = 9;
                    enabled = true;
                    hotpluggable = true;
                    order = 10;
                  }
                  {
                    id = 10;
                    enabled = true;
                    hotpluggable = true;
                    order = 11;
                  }
                  {
                    id = 11;
                    enabled = true;
                    hotpluggable = true;
                    order = 12;
                  }
                  {
                    id = 12;
                    enabled = true;
                    hotpluggable = true;
                    order = 13;
                  }
                  {
                    id = 13;
                    enabled = true;
                    hotpluggable = true;
                    order = 14;
                  }
                  {
                    id = 14;
                    enabled = false;
                    hotpluggable = true;
                  }
                  {
                    id = 15;
                    enabled = false;
                    hotpluggable = true;
                  }
                ];
              };
              iothreads = {
                count = 1;
              };
              cputune = {
                emulatorpin = {
                  cpuset = "0,8";
                };
                iothreadpin = {
                  iothread = 1;
                  cpuset = "0,8";
                };
                vcpupin = [
                  {
                    vcpu = 0;
                    cpuset = "1";
                  }
                  {
                    vcpu = 1;
                    cpuset = "9";
                  }
                  {
                    vcpu = 2;
                    cpuset = "2";
                  }
                  {
                    vcpu = 3;
                    cpuset = "10";
                  }
                  {
                    vcpu = 4;
                    cpuset = "3";
                  }
                  {
                    vcpu = 5;
                    cpuset = "11";
                  }
                  {
                    vcpu = 6;
                    cpuset = "4";
                  }
                  {
                    vcpu = 7;
                    cpuset = "12";
                  }
                  {
                    vcpu = 8;
                    cpuset = "5";
                  }
                  {
                    vcpu = 9;
                    cpuset = "13";
                  }
                  {
                    vcpu = 10;
                    cpuset = "6";
                  }
                  {
                    vcpu = 11;
                    cpuset = "14";
                  }
                  {
                    vcpu = 12;
                    cpuset = "7";
                  }
                  {
                    vcpu = 13;
                    cpuset = "15";
                  }
                ];
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
                      enabled = false;
                      name = "secure-boot";
                    }
                  ];
                };
                loader = {
                  readonly = true;
                  type = "pflash";
                  path = "${pkgs.OVMFFull.fd}/FV/OVMF_CODE.fd";
                };
                nvram = {
                  template = "${pkgs.OVMFFull.fd}/FV/OVMF_VARS.fd";
                  path = nvramFile;
                };
              };
              features = {
                acpi = { };
                apic = { };
              };
              clock = {
                offset = "utc";
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
                    present = true;
                  }

                  {
                    name = "tsc";
                    present = true;
                    mode = "native";
                  }
                ];
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
                cache = {
                  mode = "passthrough";
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
                        dev = "vdb";
                      };
                      boot = {
                        order = 1;
                      };
                    }
                    # opencore image
                    {
                      type = "file";
                      device = "disk";
                      driver = {
                        name = "qemu";
                        type = "raw";
                        cache = "writeback";
                        discard = "unmap";
                      };
                      source = {
                        file = opencoreFile;
                        startupPolicy = "mandatory";
                      };
                      target = {
                        bus = "virtio";
                        dev = "vda";
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
                        dir = "/home/${arcanum.username}/macshare";
                      };
                      target = {
                        dir = "macshare";
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
                        bus = "ps2";
                      }
                      {
                        type = "mouse";
                        bus = "ps2";
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
                  # pass pipewire to guest. requires voodoohda, which only work when installed to Library/Extensions in recent versions
                  # to disable the relevant part of SIP
                  # csrutil enable --without kext
                  # or set csr-active-config to 03000000 in opencore
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
                  hostdev = [
                    # amd gpu
                    {
                      mode = "subsystem";
                      type = "pci";
                      managed = true;
                      source = {
                        address = pci_address 13 0 0;
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
                  watchdog = {
                    model = "itco";
                    action = "none";
                  };
                };
              qemu-commandline = {
                arg = [
                  { value = "-global"; }
                  { value = "ICH9-LPC.acpi-pci-hotplug-with-bridge-support=off"; }
                  { value = "-device"; }
                  { value = "isa-applesmc,osk=ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"; }
                  { value = "-cpu"; }
                  { value = "Cascadelake-Server,vendor=GenuineIntel"; }
                ];
              };
            };
        }
      ];
    };
  };
  userPersist.directories = [
    "macshare"
    "macstore"
  ];
}
