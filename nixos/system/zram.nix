_: {
  content = {
    # Replace disk swap with zram
    zramSwap = {
      enable = true;
      memoryPercent = 100;
      priority = 100;
    };
    boot.kernel.sysctl = {
      # optimize swap on zram. these values are what pop!_os uses
      # even on a system with a fast ssd, a high swappiness value may be ideal
      "vm.swappiness" = 180;
      "vm.watermark_boost_factor" = 0;
      "vm.watermark_scale_factor" = 125;
      "vm.page-cluster" = 0;
    };
  };
}
