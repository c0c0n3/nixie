{
  description = "nixie goodness";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-21.11";
  };

  outputs = { self, nixpkgs }:
  let
    lib = import ./lib nixpkgs.lib;

    output = lib.flakes.mkOutputForCoreSystems nixpkgs;
    tex = import ./pkgs/tex/mkSysOutput.nix;

    pkgs = lib.sets.mergeAll [
      (output tex)
    ];

    modules = {};
  in
    { inherit lib; } // pkgs // modules;
}
