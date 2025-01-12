{
  cfg,
  lib,
  ...
}:
with lib;
{
  options.size = mkOption {
    type = types.int;
    default = 8192;
    description = ''
      Size in MiB. Defaults to 8GB
    '';
  };
  content.swapDevices = singleton {
    device = "/var/lib/swapfiles/swappyfiler";
    inherit (cfg) size;
    priority = 50;
  };
  persist.directories = singleton "/var/lib/swapfiles";
}
