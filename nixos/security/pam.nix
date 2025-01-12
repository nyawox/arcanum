{
  lib,
  cfg,
  ...
}:
with lib;
{
  options = {
    rssh = mkEnableOption "sudo with ssh-agent authentication"; # `ssh <hostname> -A to forward agent`
  };
  content = {
    security.pam.rssh.enable = mkIf cfg.rssh true;
    security.pam.services = {
      sudo.rssh = mkIf cfg.rssh true;
      sudo-i.rssh = mkIf cfg.rssh true;
    };
  };
}
