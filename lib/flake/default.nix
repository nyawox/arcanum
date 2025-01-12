{
  self,
  inputs,
  outputs,
  stateVersion,
  withSystem,
  ...
}:
let
  hosts = import ./hosts.nix {
    inherit
      self
      inputs
      outputs
      stateVersion
      withSystem
      ;
  };
in
{
  inherit (hosts) nixos iso;
}
