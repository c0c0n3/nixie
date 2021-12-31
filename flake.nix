{
  description = "nixie goodness";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-21.11";
  };

  outputs = { self, nixpkgs }:
  let
    lib = import ./lib nixpkgs.lib;

    output = lib.flakes.mkOutputSetByCartProdForCoreSystems nixpkgs;
    cli-tools = import ./pkgs/cli-tools/mkSysOutput.nix;
    tex = import ./pkgs/tex/mkSysOutput.nix;

    pkgs = output [ cli-tools tex ];

    modules = {};
  in
    { inherit lib; } // pkgs // modules;
}
