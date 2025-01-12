# rocm breaks frequently, it's better to keep a container option
{
  cfg,
  lib,
  arcanum,
  pkgs,
  ...
}:
with lib;
{
  options = {
    container = mkEnableOption "run on container";
    port = mkOption {
      type = types.int;
      default = 11434;
    };
    codingModel = mkOption {
      type = types.str;
      default = "hf.co/bartowski/Qwen2.5-Coder-14B-Instruct-GGUF:IQ4_XS"; # fits in vram
      description = ''
        Just an internal option to reference from other modules
      '';
    };
    chatModel = mkOption {
      type = types.str;
      default = "hf.co/bartowski/Qwen2.5-32B-Instruct-GGUF:Qwen2.5-32B-Instruct-IQ3_XS.gguf"; # fits in vram
      description = ''
        Just an internal option to reference from other modules
      '';
    };
  };
  homeConfig.services.podman.containers."ollama" = mkIf cfg.container {
    image = "docker.io/ollama/ollama:rocm";
    autoStart = true;
    autoUpdate = "registry";
    volumes = [ "/var/lib/ollama:/root/.ollama" ];
    environment = {
      HSA_ENABLE_SDMA = "0"; # without this the gpu crash
      HSA_OVERRIDE_GFX_VERSION = "9.0.0";
      OLLAMA_DEBUG = "true";
      CUDA_VISIBLE_DEVICES = "54";
      # OLLAMA_FLASH_ATTENTION = "1";
    };
    devices = [
      "/dev/dri:/dev/dri"
      "/dev/kfd:/dev/kfd"
    ];
    network = singleton "shared";
    networkAlias = singleton "ollama";
    ports = singleton "${toString cfg.port}:11434";
  };
  content = {
    modules.networking.tailscale.tags = [ "tag:admin-llm-servers" ];
    services.ollama = mkIf (!cfg.container) {
      enable = true;
      acceleration = "rocm";
      rocmOverrideGfx = "9.0.0";
      host = "[::]";
      environmentVariables = {
        HSA_ENABLE_SDMA = "0"; # without this the gpu crash
        OLLAMA_DEBUG = "true";
        CUDA_VISIBLE_DEVICES = "54";
        # OLLAMA_FLASH_ATTENTION = "1";
      };
      inherit (cfg) port;
    };
    modules.virtualisation.podman.enable = mkIf cfg.container (mkForce true);

    arcanum.sysUsers = mkIf (!cfg.container) [ "ollama" ];
    environment.systemPackages = with pkgs; [
      rocmPackages.rocminfo
      rocmPackages.rocm-smi
      oterm
      ollama
    ];
    systemd.services.ollama.after = [ "var-lib-ollama.mount" ];
  };
  persist.directories = singleton {
    directory = if cfg.container then "/var/lib/ollama" else "/var/lib/private/ollama";
    user = if cfg.container then arcanum.username else "ollama";
    group = if cfg.container then "users" else "ollama";
    mode = "750";
  };
  userPersist.directories = singleton ".ollama";
}
