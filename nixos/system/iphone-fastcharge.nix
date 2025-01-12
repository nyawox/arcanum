{
  lib,
  pkgs,
  ...
}:
{
  content.services.udev.extraRules =
    # conf
    ''
      SUBSYSTEM=="power_supply", ACTION=="change", RUN+="${lib.getExe pkgs.bash} -c 'echo Fast > %S%p/charge_type || :'"
    '';
}
