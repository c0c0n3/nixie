#
# Function to generate the Flake output for a given system.
#
{ # System label---e.g. "x86_64-linux", "x86_64-darwin", etc.
  system,
  # The Nix package set for the input system.
  sysPkgs,
  ...
}:
let
  tools = import ./env.nix { pkgs = sysPkgs; };
in {
  pkgs.${system}.cli-tools = tools;  # (*)
  packages.${system} = {
    cli-tools = tools.mkEnv { inherit system; };
  };
}
# NOTE
# Can't add the `cli-tools` set to Flake `packages` b/c Nix expects derivations
# to be in `packages`, not plain sets. Since we'd like to make available the
# `mkEnv` function, we add the set to our own `pkgs` attribute. Notice we've
# got to scope it by `system` b/c we have a different set for each system.
# Details over here:
#
# - https://github.com/c0c0n3/nixie/wiki/Flake-utils
#
