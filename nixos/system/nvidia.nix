{
  cfg,
  config,
  lib,
  ...
}:
with lib;
{
  options = {
    modeSet = mkOption {
      type = types.bool;
      default = false;
    };
    prime = mkOption {
      type = types.bool;
      default = false;
    };
  };
  content = {
    modules.security.hardening.compatibility = {
      no-lockdown = mkForce true;
      allow-unsigned-modules = mkForce true;
    };
    services.xserver.videoDrivers = singleton "nvidia";
    boot = {
      kernelParams = lib.mkMerge [
        # ["nvidia.NVreg_EnableGpuFirmware=0"] # Disable GSP Firmware. reduces stutter on wayland
        # prime offload automatically enables modeset
        (mkIf (!cfg.modeSet)
          # override it with priority, later kernel params are prioritized
          (mkAfter [ "nvidia-drm.modeset=0" ])
        )
      ];
      # required for cuda tasks (including nvenc)
      kernelModules = singleton "nvidia-uvm"; # for some reason it's not being loaded automatically
    };
    hardware = {
      graphics = {
        enable = mkDefault true;
        enable32Bit = mkDefault true;
      };
      nvidia = {
        modesetting.enable = mkIf (!cfg.modeSet) false;
        open = true; # open kernel modules rely on GSP (causing stutters) to work. https://github.com/NVIDIA/open-gpu-kernel-modules/issues/693
        powerManagement.enable = false;
        powerManagement.finegrained = false;
        nvidiaSettings = true;
        prime = mkIf cfg.prime {
          amdgpuBusId = "PCI:13:0:0";
          nvidiaBusId = "PCI:1:0:0";
          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
          # reverseSync.enable = true; # supposed to make amdgpu the default
        };
        package = config.boot.kernelPackages.nvidiaPackages.beta; # 565 supposedly fixes stutters in open nvidia module
      };
    };
  };
}
