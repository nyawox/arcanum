{
  lib,
  ...
}:
let
  # Automatically run GC whenever there is not enough space left
  # Bytes
  extraOptions =
    # conf
    ''
      min-free = ${toString (100 * 1024 * 1024)}
      max-free = ${toString (1024 * 1024 * 1024)}
      builders-use-substitutes = true
    '';
  experimental-features = [
    "nix-command"
    "flakes"
  ];
in
{
  content = {
    # this is annoying
    boot.binfmt.addEmulatedSystemsToNixSandbox = lib.mkForce false;
    nix = {
      settings = {
        trusted-users = [ "@wheel" ];
        allowed-users = [ "@wheel" ];
        extra-platforms = [
          "i686-linux"
          "x86_64-linux"
          # "aarch64-linux" # enable this when remote builder is offline
        ];
        inherit experimental-features;
      };
      optimise.automatic = true;
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
      inherit extraOptions;
    };
  };
  homeConfig = {
    nix = {
      settings = {
        inherit experimental-features;
      };
      inherit extraOptions;
    };
  };
  userPersist.directories = lib.singleton ".local/share/nix"; # trusted-settings.json
}
