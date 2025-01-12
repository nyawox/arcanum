{
  lib,
  arcanum,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  virtLib = inputs.nixvirt.lib;
in
{
  imports = [
    inputs.nixvirt.nixosModules.default
  ];
  content = {
    modules.system.maxmem.enable = mkForce true;
    modules.security.hardening.compatibility.allow-ip-forward = mkForce true;

    boot = {
      kernelModules = [ "vfio-pci" ];
      kernelParams = mkOverride 100 [
        # hardening profile disables this by default
        "amd_iommu=on"
        "iommu=pt"
      ];
      extraModprobeConfig = "options kvm_amd nested=1"; # enable nested hypervisor, such as hyperv on kvm
    };

    virtualisation = {
      # without "d". nixvirt module
      libvirt = {
        enable = true;
        verbose = true;
        swtpm.enable = true;
        connections."qemu:///system".networks = [
          {
            active = true;
            definition = virtLib.network.writeXML (
              virtLib.network.templates.bridge {
                uuid = "28c6c4b6-6202-4d1d-8a40-0c6db3b55f85";
                subnet_byte = 122;
              }
            );
          }
        ];
      };
      libvirtd = {
        onBoot = "ignore";
        onShutdown = "shutdown";
        qemu = {
          vhostUserPackages = [ pkgs.virtiofsd ]; # file sharing
          runAsRoot = true; # change the user manually below
          # required for pipewire backend
          verbatimConfig = ''
            user = "${arcanum.username}"
            group = "users"
          '';
        };
      };
    };
    users.users."${arcanum.username}".extraGroups = lib.singleton "libvirtd";
    services.spice-vdagentd.enable = true;
    programs.virt-manager.enable = true;
    environment.systemPackages = with pkgs; [
      virt-viewer
      spice
      spice-gtk
      spice-protocol
    ];
  };
  persist.directories = singleton {
    directory = "/var/lib/libvirt";
    user = "root";
    group = "root";
    mode = "756";
  };
}
