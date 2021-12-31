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
  pkgs.cli-tools = tools;
  packages.${system} = {
    cli-tools = tools.mkEnv { inherit system; };
  };
}
