nixlib:                                           # (1)
{
  flakes = import ./flakes.nix nixlib;
  paths  = import ./paths.nix nixlib;
  sets   = import ./sets.nix nixlib;
}
# NOTE
# 1. Nixpkgs lib. You've got to pass into this function the `lib` attribute
# of a suitable Nixpkgs set---i.e. a version the code in our lib can work
# with.
