{ pkgs, ... }:
{
  home.packages = with pkgs; [
    helix
    unzip
    unar
    killall
    efibootmgr
    btrfs-progs
    parted
    glxinfo
    bc
    ripgrep
    aria2
    e2fsprogs
  ];
}
