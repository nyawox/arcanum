{
  config,
  lib,
  ...
}:
{
  options = with lib; {
    arcanum.ignoredWarnings = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        list of warnings to ignore
      '';
    };
    warnings = mkOption {
      apply = builtins.filter (w: !(builtins.elem w config.arcanum.ignoredWarnings));
    };
  };
}
