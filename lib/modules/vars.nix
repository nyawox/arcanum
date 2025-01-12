{ lib, ... }:
with lib;
let
  mkStrOption =
    description:
    mkOption {
      type = types.str;
      default = "";
      inherit description;
    };
  mkNullableStrOption =
    description:
    mkOption {
      type = types.nullOr types.str;
      default = null;
      inherit description;
    };
in
{
  options.arcanum = {
    deploy = mkEnableOption "Add the host to `flake.deployment`";
    username = mkNullableStrOption "Username";
    domain = mkStrOption "Domain name";
    serviceName = mkStrOption "Name of the service";
    personalMail = mkStrOption "Primary personal mail";
    personalMail2 = mkStrOption "2nd personal mail";
    personalMail3 = mkStrOption "3rd personal mail";
    # networking
    localhoax-ip = mkStrOption "localhoax ipv6";
    localhoax-ip4 = mkStrOption "localhoax ipv4";
    lokalhost-ip = mkStrOption "lokalhost ipv6";
    lokalhost-ip4 = mkStrOption "lokalhost ipv4";
    lokalhost-gateway4 = mkStrOption "lokalhost ipv4 gateway";
    localpost-ip4 = mkStrOption "localpost ipv4";
    localtoast-ip4 = mkStrOption "localtoast ipv4";
    localghost-ip = mkStrOption "localghost ipv6";
    localghost-ip4 = mkStrOption "localghost ipv4";
    localghost-gateway = mkStrOption "localghost ipv6 gateway";
    localcoast-ip = mkStrOption "localcoast ipv6";
    localcoast-ip4 = mkStrOption "localcoast ipv4";
    localcoast-gateway = mkStrOption "localcoast ipv6 gateway";
    localhostage-ip4 = mkStrOption "localhostage ipv4";
  };
}
