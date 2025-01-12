_: {
  # grep "" /sys/block/*/queue/scheduler
  # https://wiki.archlinux.org/title/Improving_performance#Changing_I/O_scheduler
  content.services.udev.extraRules = # ini
    ''
      # HDD
      ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"

      # SSD
      ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="bfq"

      # NVMe SSD
      ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
    '';
}
