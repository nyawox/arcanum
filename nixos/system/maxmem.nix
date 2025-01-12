# increase the maximum number of memory map areas a process can have
# required for memory intensive applications
{
  lib,
  ...
}:
{
  content.boot.kernel.sysctl."vm.max_map_count" = lib.mkForce 2147483642; # set to max int - 5.
}
