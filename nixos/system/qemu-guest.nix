_: {
  content = {
    boot = {
      initrd.availableKernelModules = [
        "ata_piix"
        "uhci_hcd"
        "virtio_pci"
        "sr_mod"
        "sd_mod"
        "virtio_blk"
        "virtio_mmio"
        "virtio_scsi"
        "9p"
        "9pnet_virtio"
      ];
      initrd.kernelModules = [
        "virtio_scsi"
        "virtio_balloon"
        "virtio_console"
        "virtio_rng"
        # ethernet module for initrd ssh
        "virtio_net"
      ];
    };
  };
}
