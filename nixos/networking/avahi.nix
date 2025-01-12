_: {
  content = {
    # ssh with hostanme
    services.avahi = {
      enable = true;
      openFirewall = false;
      # publish/announce machine
      publish = {
        enable = true;
        addresses = true;
        domain = true;
        userServices = true;
        hinfo = true;
        workstation = true;
      };
    };
  };
}
