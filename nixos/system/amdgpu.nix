{
  cfg,
  lib,
  pkgs,
  arcanum,
  ...
}:
with lib;
let
  pptFile = "${arcanum.configPath}/system/amdgpu/amdgpu_ppt.bin";
  card = "card1"; # TODO ensure card0 is always amdgpu
  writePowerPlay = pkgs.writeShellScript "writePowerPlay" ''
    cp ${pptFile} /sys/class/drm/${card}/device/pp_table
  '';
in
{
  options = {
    modeSet = mkOption {
      type = types.bool;
      default = false;
    };
    disableEfiFb = mkOption {
      type = types.bool;
      default = false;
    };
  };
  content = {
    services.xserver.videoDrivers = [ "amdgpu" ];

    boot.kernelParams = mkIf cfg.modeSet [
      "amdgpu.modeset=1"
      "amdgpu.seamless=1"
      "amdgpu.dc=1" # displaycore
      "amdgpu.ppfeaturemask=0xffffffff" # enable overclocking
      (mkIf cfg.disableEfiFb "video=efifb:off")
    ];
    hardware = {
      graphics = {
        enable = mkDefault true;
        enable32Bit = mkDefault true;
        extraPackages = with pkgs; [
          vaapiVdpau
          libvdpau-va-gl
        ];
      };
      amdgpu = {
        initrd.enable = true;
        opencl.enable = true;
      };
    };
    systemd.services.amdgpu-ppt = {
      enable = true;
      description = "Enable AMDGPU custom PowerPlay table";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${writePowerPlay}";
        Restart = "on-failure";
        RestartSec = "60s";
        ReadOnlyPaths = "${pptFile}";
        ReadWritePaths = "/sys/class/drm";
        ProtectSystem = "full";
        PrivateTmp = true;
      };
    };
    # overclock, undervolt, set fan curves
    environment.systemPackages = with pkgs; [ lact ];
    systemd.packages = with pkgs; [ lact ];
    # systemd.services.lactd.wantedBy = ["multi-user.target"];
  };
  persist.directories = singleton "/etc/lact";
}
