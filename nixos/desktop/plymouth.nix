{
  lib,
  ...
}:
with lib;
{
  content = {
    boot.plymouth.enable = mkDefault true;
    modules.desktop.silentboot.enable = mkDefault true;
    # smoother transition between efi and plymouth,
    # especially on amdgpu
    # shouldn't have any issue enabling by default in most cases
    boot.kernelParams = [ "plymouth.use-simpledrm" ];
  };
}
