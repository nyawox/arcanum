_: {
  homeConfig = {
    programs.carapace = {
      enable = true;
      enableNushellIntegration = true;
    };
  };
  userPersist.directories = [
    ".config/carapace"
    ".cache/carapace"
  ];
}
