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
    "aarch64-linux" "aarch64-darwin" "x86_64-linux" "x86_64-darwin"
  ];

  # mkOutput :: [str] -> set -> (str -> set -> set) -> set
  # mkOutput   systems  nixpkgs     mkSysOutput       Flake output set
  #
  # Build a Flake output set, i.e. the `outputs` attribute set.
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
  # This builder tries to reduce the boilerplate needed to generate a Flake
  # output set by using an input `mkSysOutput` function that can produce an
  # output set parameterised by system as in e.g.
  #
  #     mkSysOutput = { system, ... }: {
  #       packages.${system} = {
  #         my-app = {/* derivation */};
  #         my-tool = {/* derivation */};
  #       };
  #     };
  #
  # It then uses `mkSysOutput` to generate a system output set for each
  # input system and finally merges the system output sets into one.
  # Notice you'd typically use this builder when you want to output
  # the same derivations for a whole bunch of systems. If you need
  # to output different derivations for different systems, you're better
  # off with another builder. But outputting attributes that don't depend
  # on the input systems (e.g. a lib function) is okay, since they'll all
  # be the same for each system output set produced by `mkSysOutput`, so
  # when this builder merges the individual system outputs into the final
  # Flake output, you'll end up with those attributes in place as you'd
  # expect.
  #
  # Params:
  # - systems: a list of system labels, e.g. `["x86_64-linux" "aarch64-linux"]`.
  # - nixpkgs: the Nix package set from which to source input packages.
  # - mkSysOutput: a function to build the Flake output for a given system.
  #   The function takes an input set with two attributes
  #   * system: one of the labels in `systems`
  #   * sysPkgs: the Nix package set for `system`
  #   and returns the Flake output for `system` as explained earlier.
  mkOutput = systems: nixpkgs: mkSysOutput:
  let
    buildOutputSet = system: mkSysOutput {
      inherit system;
      sysPkgs = nixpkgs.legacyPackages.${system};
    };
    outputs =  builtins.map buildOutputSet systems;
  in
    sets.mergeAll outputs;

  # Shortcut to call `mkOutput` with `coreSystems` as first argument.
  mkOutputForCoreSystems = mkOutput coreSystems;

}
