{ pkgs, ... }:
{
  home.packages = with pkgs; [
    pciutils
    btrfs-progs
    parted
    glxinfo
  ];
}
