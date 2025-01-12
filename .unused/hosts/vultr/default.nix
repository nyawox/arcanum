_: {
  modules = {
    sysconf = {
      sshluks.enable = true;
      bluetooth.enable = false;
    };
    services = {
      tailscale.enable = true;
      # acme.enable = true;
      # headscale.enable = true;
      # searxng.enable = true;
      # frp.enable = true;
    };
    desktop = {
      pipewire.enable = false;
      plymouth.enable = false;
    };
  };

  tmpfsroot = {
    enable = false;
    size = "256M";
  };
  disk.encryption = {
    enable = true;
    pbkdf = "pbkdf2";
  };
  disk.device = "/dev/vda";
  esp.mbr = true;
  esp.size = "256M";
  systemd.network.networks."ens3" = {
    matchConfig.Name = "ens3";
    address = [ "149.28.98.185/23" ];
    routes = [ { Gateway = "149.28.98.1"; } ];
    # make the routes on this interface a dependency for network-online.target
    linkConfig.RequiredForOnline = "routable";
  };
  boot.kernelParams = [ "ip=149.28.98.185" ];
  psilocybin.enable = false; # disable this otherwise vnc becomes unusable

  # Kernel modules required to boot on virtual machine
  # Make sure to include ethernet module to remote unlock luks
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "sr_mod"
    "virtio_blk"
    "virtio-net"
  ];
}
