_: {
  homeConfig = {
    programs.broot = {
      enable = true;
      settings = {
        modal = true;
        imports = [
          {
            luma = [
              "dark"
              "unknown"
            ];
            file = "skins/catppuccin-mocha.hjson";
          }
        ];
      };
    };
  };
}
