_: {
  content.services.udisks2 = {
    enable = true;
    settings = {
      "mount_options.conf" = {
        defaults = {
          # no need to default to lower compression levels unless it's a fast SSD
          btrfs_defaults = [
            "noatime"
            "compress-force=zstd:3"
          ];
        };
      };
    };
  };
}
