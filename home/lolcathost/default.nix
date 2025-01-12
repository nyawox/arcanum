{
  lib,
  pkgs,
  ...
}:
{
  imports = lib.filter (file: lib.hasSuffix ".nix" file && file != ./default.nix) (
    lib.filesystem.listFilesRecursive ./.
  );
  home.file.".local/share/PrismLauncher/themes/Catppuccin-Mocha".source =
    let
      zip = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/catppuccin/prismlauncher/423e359d6c17b0339e8c851bb2953bcf5c7e1e49/themes/Mocha/Catppuccin-Mocha.zip";
        sha256 = "03y76qlsnrjkvd79his5jlaq9rqp2j3x1g101js0sm4iiv4q0l5a";
      };
    in
    pkgs.stdenv.mkDerivation {
      name = "catppuccin-prismlauncher";
      nativeBuildInputs = [ pkgs.unzip ];
      src = zip;
      sourceRoot = ".";
      unpackCmd = "unzip $src";
      dontConfigure = true;
      dontBuild = true;
      installPhase = ''
        mkdir -p $out
        cp -R Catppuccin-Mocha/* $out/
      '';
    };
}
