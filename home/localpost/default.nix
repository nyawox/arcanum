{ lib, ... }:
{
  imports = lib.filter (file: lib.hasSuffix ".nix" file && file != ./default.nix) (
    lib.filesystem.listFilesRecursive ./.
  );
}
