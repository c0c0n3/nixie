#
# Utils to work with Flakes.
# This is a function that takes the Nixpkgs lib as input and returns a set
# with the utils.
#
nixlib:
let
  sets = import ./sets.nix nixlib;
in rec
{
  # Core systems most of our packages should build on.
  # Nix identifies systems with platform labels, see
  # - https://nixos.org/manual/nix/stable/installation/supported-platforms.html
  # - https://github.com/NixOS/rfcs/blob/master/rfcs/0046-platform-support-tiers.md
  # - https://nixos.org/manual/nixpkgs/stable/#var-meta-platforms
  coreSystems = [
     "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"
  ];

  # Combine Flake system-specific outputs into the final Flake output set,
  # i.e. the `outputs` attribute set.
  #
  # Typically, a Flake output set depends on the systems the Flake targets.
  # Nix identifies systems with labels like "x86_64-linux" and expects the
  # Flake to group output derivations by system as in e.g.
  #
  #     packages.x86_64-linux = {
  #       my-app = {/* derivation */};
  #       my-tool = {/* derivation */};
  #     };
  #     packages.aarch64-linux = {
  #       my-app = {/* derivation */};
  #       my-tool = {/* derivation */};
  #     };
  #
  # One way to build the Flake output set is to produce a set for each system
  # the Flake targets and then combine these sets into the final Flake output
  # set. This is basically what `buildOutputSet` does. The process of producing
  # a system-specific output is encapsulated by a `mkSysOutput` function that
  # given a system label and the set of Nix packages for that system outputs
  # a set with the attributes that the system at hand contributes to the final
  # Flake output set, e.g.
  #
  #     mkSysOutput = { system, ... }: {
  #       packages.${system} = {
  #         my-app = {/* derivation */};
  #         my-tool = {/* derivation */};
  #       };
  #     };
  #
  # Here's some pseudo (dependent) types to explain what `buildOutputSet` does.
  #
  # System =  "aarch64-linux" | ...  -- all valid Nix system labels
  # Nixpkgs :: set                   -- Flake's input containing Nix packages
  #                                     for each system (github:NixOs/nixpkgs)
  # PkgsOf :: System -> set          -- Nix package set for a system
  # OutGen = { system :: System;
  #            mkSysOutput :: System -> PkgsOf System -> set;
  #         -- param names:   ^ system  ^ sysPkgs
  #          }
  #
  # buildOutputSet :: Nixpkgs -> [OutGen] -> set
  # buildOutputSet nixpkgs [g1, .., gN] =
  #     (g1.mkSysOutput g1.system (pkgsOf g1.system))
  #   + ...
  #   + (gN.mkSysOutput gN.system (pkgsOf gN.system))
  #
  # where `+` merges attribute sets recursively.
  #
  # Plus, you can make `buildOutputSet` use Flake overlays by adding a
  # custom `mkOverlays` function to the `nixpkgs` set. The function takes
  # a system and returns a list of Flake overlays for that system. E.g.
  #
  #     inputPkgs = nixpkgs // {
  #        mkOverlays = system: [ gomod2nix.overlays.default ];
  #                               # ^ works w/ all core systems
  #     };
  #     pkgs = buildOutputSet inputPkgs outGens
  #
  # every function in `outGens` now gets passed a package set containing
  # `gomod2nix` plus whatever was already in `nixpkgs`.
  #
  buildOutputSet = nixpkgs: outGens:
  let
    mkOverlays = nixpkgs.mkOverlays or (system: []);
    genOutput = outGen:
      outGen.mkSysOutput {
        system  = outGen.system;
        sysPkgs = import nixpkgs {
          system = outGen.system;
          overlays = mkOverlays outGen.system;
        };
    };
    sysOutputs = builtins.map genOutput outGens;
  in
    sets.mergeAll sysOutputs;

  # Build a Flake output set by combining the outputs produced by the
  # given `mkSysOutput` function when applied to each input system.
  # This is just a variation on the theme of `buildOutputSet` where the
  # `mkSysOutput` function is the same for all systems. Using the same
  # pseudo types as in `buildOutputSet`, here's a high-level description
  # of what `mkOutputSet` does:
  #
  # mkOutputSet :: [System] -> Nixpkgs -> (System -> PkgsOf System -> set)
  #                -> set
  # mkOutputSet [s1, .., sN] nixpkgs mkSysOutput =
  #     (mkSysOutput s1 (pkgsOf s1))
  #   + ...
  #   + (mkSysOutput sN (pkgsOf sN))
  #
  # where `+` merges attribute sets recursively.
  #
  # Notice you'd typically use `mkOutputSet` when you want to output the same
  # derivations for a whole bunch of systems. If you need to output different
  # derivations for different systems, you're better off with `buildOutputSet`.
  # But outputting attributes that don't depend on the input systems (e.g. a
  # lib function) is okay, since they'll all be the same for each system output
  # set produced by `mkSysOutput`, so when `mkOutputSet` merges the individual
  # system outputs into the final Flake output, you'll end up with those
  # attributes in place as you'd expect.
  mkOutputSet = systems: nixpkgs: mkSysOutput:
  let
    mkOutGen = system: { inherit system mkSysOutput; };
    outGens  = builtins.map mkOutGen systems;
  in
    buildOutputSet nixpkgs outGens;

  # Shortcut to call `mkOutputSet` with `coreSystems` as first argument.
  mkOutputSetForCoreSystems = mkOutputSet coreSystems;

  # Call `buildOutputSet` with the output generators resulting from combining
  # the input systems and `mkSysOutput` functions in all possible ways.
  # Using the same pseudo types as in `buildOutputSet`, here's a high-level
  # description of what `mkOutputSetByCartProd` does:
  #
  #     nixpkgs :: Nixpkgs
  #
  #     systems :: [System]
  #     systems = [s1, .., sM]
  #
  #     mkSysOutputs :: [System -> PkgsOf System -> set]
  #     mkSysOutputs = [f1, .., fN]
  #
  #     mkOutputSetByCartProd systems nixpkgs mkSysOutputs =
  #       buildOutputSet nixpkgs [
  #         { system = s1; mkSysOutput = f1; }
  #         ...
  #         { system = s1; mkSysOutput = fN; }
  #         ...
  #         { system = sM; mkSysOutput = f1; }
  #         ...
  #         { system = sM; mkSysOutput = fN; }
  #       ]
  #
  mkOutputSetByCartProd = systems: nixpkgs: mkSysOutputs:
  with builtins;
  let
    xs = map (system: { inherit system; }) systems;
    ys = map (mkSysOutput: { inherit mkSysOutput; }) mkSysOutputs;
    outGens = sets.cartProd xs ys;
  in
    buildOutputSet nixpkgs outGens;

  # Shortcut to call `mkOutputSetByCartProd` with `coreSystems` as first
  # argument.
  mkOutputSetByCartProdForCoreSystems = mkOutputSetByCartProd coreSystems;

}
