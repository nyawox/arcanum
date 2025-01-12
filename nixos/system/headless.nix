{ lib, ... }:
{
  content = {
    systemd = {
      services = {
        "serial-getty@ttyS0".enable = lib.mkDefault false;
        "serial-getty@hvc0".enable = false;
        "getty@tty1".enable = false;
        "autovt@".enable = false;
      };
      enableEmergencyMode = false;
    };
    boot.kernelParams = [
      "vga=0x317"
      "nomodeset"
    ];
    boot.loader.grub.splashImage = null;
  };
}
