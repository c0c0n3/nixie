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
  tex = import ./env.nix { pkgs = sysPkgs; };
in {
  pkgs.${system}.tex = tex;  # (*)
  packages.${system} = {
    tex = tex.defaultEnv;
  };
}
# NOTE
# Can't add the `tex` set to Flake `packages`. In fact, this won't work
#
#    packages.${system}.tex = import ./env.nix { pkgs = sysPkgs; };
#
# b/c Nix expects derivations to be in `packages`, not plain sets. Since
# we'd like to make available the `mkEnv` function, we add the set to our
# own `pkgs` attribute. Notice we've got to scope it by `system`, otherwise
# when merging the sets produced by this function, the last `pkgs.tex` will
# override all the others produced by previous function calls.
# Details over here:
#
# - https://github.com/c0c0n3/nixie/wiki/Flake-utils
#
