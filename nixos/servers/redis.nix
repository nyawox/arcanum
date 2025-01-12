# mostly just a placeholder module to refer `modules.servers.redis.enable` in several services
{
  lib,
  pkgs,
  ...
}:
{
  content.environment.systemPackages = lib.singleton pkgs.redis-dump;
}
