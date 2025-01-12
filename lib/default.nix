{ config, ... }:
let
  inherit (config) arcanum;
in
{
  configPath = ../config;
  secretPath = ../secrets;
  varPath = ../var;
  inherit (arcanum)
    username
    domain
    serviceName
    personalMail
    personalMail2
    personalMail3
    localhoax-ip
    localhoax-ip4
    lokalhost-ip
    lokalhost-ip4
    lokalhost-gateway4
    localpost-ip4
    localtoast-ip4
    localghost-ip
    localghost-ip4
    localghost-gateway
    localcoast-ip
    localcoast-ip4
    localcoast-gateway
    localhostage-ip4
    ;
  internal = "${config.modules.networking.wireguard.interface}.${arcanum.domain}";
  homeCfg = config.home-manager.users.${arcanum.username};
}
