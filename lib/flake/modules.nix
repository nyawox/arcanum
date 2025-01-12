{
  lib,
  pkgs,
  system,
  self,
  inputs,
  hostname,
  platform,
  stateVersion,
  ...
}:
with lib;
let
  commonArgs = {
    inherit
      pkgs
      system
      self
      inputs
      hostname
      platform
      stateVersion
      ;
  };

  # Module path parsing, return namespace (e.g. services,networking) and name (e.g. postgresql,wireguard)
  parseModulePath =
    file:
    let
      fullPath = toString file;
      relativePath =
        let
          parts = splitString "/nixos/" fullPath;
        in
        if builtins.length parts > 1 then last parts else throw "Module path must be under nixos/"; # Safe measure
      # Remove .nix suffix and split into parts
      cleanPath = removeSuffix ".nix" relativePath;
      parts = splitString "/" cleanPath;
    in
    if builtins.length parts >= 2 then
      {
        namespace = builtins.elemAt parts 0;
        name = builtins.elemAt parts 1;
      }
    else
      throw "Module path must be in format 'nixos/<namespace>/<name>.nix'";

  processModuleContent = rawModule: args: if isFunction rawModule then rawModule args else rawModule;

  mkBoilerplate =
    { path, moduleContent }:
    {
      options.modules.${path.namespace}.${path.name} = {
        enable = mkEnableOption "Enable ${path.name}";
      } // (moduleContent.options or { });

      imports = moduleContent.imports or [ ];
    };

  mkModuleConfig =
    {
      config,
      cfg,
      moduleContent,
    }:
    mkMerge (
      [
        (mkIf cfg.enable moduleContent.content or { })
        (mkHelperConfig { inherit config cfg moduleContent; })
        {
          home-manager.sharedModules = moduleContent.homeImports or [ ];
        }
      ]
      ++ (moduleContent.extraConfig or [ ])
    );

  mkHelperConfig =
    {
      config,
      cfg,
      moduleContent,
    }:
    mkIf cfg.enable {
      environment.persistence."/persist" = {
        users.${config.arcanum.username} = { } // (moduleContent.userPersist or { });
      } // (moduleContent.persist or { });
      home-manager.sharedModules = singleton (moduleContent.homeConfig or { });
    };

  mkModule =
    file: rawModule:
    { config, lib, ... }:
    let
      path = parseModulePath file;
      cfg = config.modules.${path.namespace}.${path.name};

      args = commonArgs // {
        inherit cfg config lib;
        arcanum = import ../default.nix { inherit config; };
      };

      moduleContent = processModuleContent rawModule args;

      boilerplate = mkBoilerplate { inherit path moduleContent; };
    in
    boilerplate
    // {
      config = mkModuleConfig { inherit config cfg moduleContent; };
    };

  # Collect and process all modules
  processModules =
    modulesPath:
    let
      findModules = # Find all .nix files in nixos/ directory recursively
        dir:
        let
          contents = builtins.readDir dir;

          handleEntry =
            name: type:
            let
              path = dir + "/${name}";
              processNixFile = path: singleton (mkModule path (import path)); # Import and process the module if it's a `.nix` file
            in
            if type == "regular" && hasSuffix ".nix" name then
              processNixFile path
            else if type == "directory" then
              findModules path
            else
              [ ];
        in
        flatten (mapAttrsToList handleEntry contents);
    in
    findModules modulesPath;

  processHostContent = rawModule: args: if isFunction rawModule then rawModule args else rawModule;

  mkHostModule =
    _file: rawModule:
    { config, lib, ... }:
    let
      args = commonArgs // {
        inherit config lib;
        arcanum = import ../default.nix { inherit config; };
      };
    in
    processHostContent rawModule args;

  processHostModules =
    let
      genericConfig = mkHostModule ../../hosts/generic.nix (import ../../hosts/generic.nix);

      hostPath = ../../hosts + "/${hostname}";
      hostConfig =
        if builtins.pathExists (hostPath + "/default.nix") then
          mkHostModule (hostPath + "/default.nix") (import (hostPath + "/default.nix"))
        else if builtins.pathExists (hostPath + ".nix") then
          mkHostModule (hostPath + ".nix") (import (hostPath + ".nix"))
        else
          throw "No configuration found for host '${hostname}'";
    in
    [
      genericConfig
      hostConfig
    ];
in
{
  inherit processModules processHostModules;
}
