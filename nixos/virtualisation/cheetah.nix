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
  options.guestName = mkOption {
    type = types.str;
    default = "cheetah";
  };
  content = {
    modules.virtualisation.libvirtd.enable = mkForce true;
    # without "d". nixvirt module
    virtualisation.libvirt.connections."qemu:///system" = {
      pools = [
        {
          active = true;
          definition = virtLib.pool.writeXML {
            name = "${cfg.guestName}";
            uuid = "4988e01a-cf6e-47c2-a7d1-f54a7f52651e";
            type = "dir";
            target = {
              path = "/home/${arcanum.username}/vmstore/${cfg.guestName}";
            };
          };
          volumes = [
            {
              definition = virtLib.volume.writeXML {
                name = "${cfg.guestName}.qcow2";
                capacity = {
                  count = 16;
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
              storageFile = "/home/${arcanum.username}/vmstore/${cfg.guestName}/${cfg.guestName}.qcow2";
              isoFile = "/home/${arcanum.username}/vmstore/${cfg.guestName}/${cfg.guestName}.iso";
            in
            virtLib.domain.writeXML {
              type = "qemu";
              name = "${cfg.guestName}";
              uuid = "e3d38bb4-0b99-4aef-98ce-d97afee2b16d";
              memory = {
                count = 2;
                unit = "GiB";
              };
              vcpu = {
                placement = "static";
                count = 1;
              };
              os = {
                type = "hvm";
                arch = "ppc";
                machine = "mac99";
              };
              clock.offset = "utc";
              on_poweroff = "destroy";
              on_reboot = "restart";
              on_crash = "destroy";
              devices = {
                emulator = "${pkgs.qemu}/bin/qemu-system-ppc";
                controller = [
                  {
                    type = "usb";
                    index = 0;
                    model = "piix3-uhci";
                    address = {
                      type = "pci";
                      domain = 0;
                      bus = 0;
                      slot = 2;
                      function = 0;
                    };
                  }
                  {
                    type = "pci";
                    index = 0;
                    model = "pci-root";
                  }
                ];
                graphics = {
                  type = "spice";
                  listen = {
                    type = "none";
                  };
                  image = {
                    compression = false;
                  };
                  gl = {
                    enable = false;
                  };
                };
                video = {
                  model = {
                    type = "none";
                  };
                };
                memballoon = {
                  model = "none";
                };
              };
              qemu-commandline = {
                arg = [
                  { value = "-M"; }
                  { value = "mac99"; }
                  { value = "-device"; }
                  { value = "ide-hd,bus=ide.0,drive=Macintosh"; }
                  { value = "-drive"; }
                  {
                    value = "if=none,format=qcow2,media=disk,id=Macintosh,file=${storageFile},discard=unmap,detect-zeroes=unmap";
                  }
                  { value = "-device"; }
                  { value = "ide-cd,bus=ide.0,drive=Installer"; }
                  { value = "-drive"; }
                  {
                    value = "if=none,format=raw,media=disk,id=Installer,file=${isoFile},discard=unmap,detect-zeroes=unmap";
                  }
                  { value = "-device"; }
                  { value = "sungem,mac=2A:84:84:06:3E:78,netdev=net0"; }
                  { value = "-netdev"; }
                  { value = "user,id=net0"; }
                  { value = "-device"; }
                  { value = "VGA,edid=on"; }
                  { value = "-prom-env"; }
                  { value = "boot-args=-v"; }
                  { value = "-prom-env"; }
                  { value = "vga-ndrv?=true"; }
                  { value = "-prom-env"; }
                  { value = "auto-boot?=true"; }
                  { value = "-g"; }
                  { value = "1920x1080x32"; }
                  { value = "-boot"; }
                  { value = "c"; } # set to d when booting from iso
                ];
              };
            };
        }
      ];
    };
  };
  userPersist.directories = singleton "vmstore/${cfg.guestName}";
}
