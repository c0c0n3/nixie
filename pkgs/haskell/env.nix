#
# Haskell DevEnv with widely used libs and tools.
#
# What's in the box? The latest (Nixpkgs stable) GHC with the following
# Haskell packages and tools:
#
# - The whole (now defunct?!) Haskell platform (except for Stack):
#   https://www.haskell.org/platform/contents.html
# - All the libraries `haskell-lang` used to recommend (this site's gone too):
#   https://haskell-lang.org/libraries
# - `cabal2nix` to Nixify Cabal projects.
# - The tools needed by the Haskell Spacemacs layer. (Dante back-end.)
# - Some other useful tools: Hakyll, Pandoc, Shake, Diagrams+Graphviz.
#
# Even though we only explicitly request to install about fifty packages,
# all their dependencies get installed too and registered with GHC, so you
# end up with over 300 packages available to you. (Use `ghc-pkg list` to
# list them all.) To install even more packages in the same environment,
# use the `mkEnv` function.
#
# This is a quick, hassle-free way to try Haskell and it should still work
# decently for amateur projects. For complex projects, you'll probably need
# to roll out your own Nix expressions or even better, use something like
# `haskell.nix` to translate your Cabal or Stack project and its dependencies
# into Nix code.
#
{ pkgs, ... }: rec {

  # List the default set of Haskell packages included in our environment.
  # Params:
  # - ps: Haskell package set from Nixpkgs containing the below packages.
  #
  listHBasePkgs = ps: with ps; [
    # Programs and Tools
    # ------------------
    # - Haskell platform tools except for Stack.
    alex cabal-install /* haddock */ happy hscolour
    #                     ^ NOTE (1)

    # - needed by Spacemacs Haskell layer and generally useful anyway.
    apply-refact hlint stylish-haskell hasktags hoogle
    # - other tools I've found useful.
    hakyll pandoc pandoc-types shake hpack

    # Libs
    # ----
    # Most of them already get installed as deps of the programs and tools
    # above but let's list them anyway for the sake of being explicit.

    # - Haskell platform libs.
    async attoparsec call-stack case-insensitive fgl fixed GLURaw GLUT
    half hashable haskell-src html HTTP HUnit integer-logarithms mtl
    network network-uri ObjectName OpenGL OpenGLRaw parallel parsec
    primitive QuickCheck random regex-base regex-compat regex-posix
    scientific split StateVar stm syb text tf-random transformers
    unordered-containers vector zlib

    # - Core libs recommended by haskell-lang but not included in the
    #   Haskell platform.
    aeson criterion optparse-applicative safe-exceptions
    # - Common libs recommended by haskell-lang but not included in the
    #   Haskell platform, excluding hspec and tasty.
    conduit http-client pipes wreq

    # - Tasty framework with the components I've found most useful.
    tasty tasty-hunit tasty-golden tasty-smallcheck tasty-quickcheck
    tasty-html tasty-discover

    # - Other libs I've found useful.
    here diagrams /* diagrams-graphviz */
    #                ^ NOTE (1)
  ];

  # Build a Haskell environment containing the base packages plus any extras
  # given in the argument. E.g.
  #
  #     myHaskell = mkEnv ["project-m36"];
  #
  # This function returns a derivation for the Haskell environment.
  mkEnv = extraPkgs:
  with builtins;
  let
    toDrv = ps: name: ps.${name};
    hPkgs = ps: (listHBasePkgs ps) ++ (map (toDrv ps) extraPkgs);
    hEnv = pkgs.haskellPackages.ghcWithPackages hPkgs;
  in with pkgs; buildEnv {
    name = "haskell-devenv";
    paths = [ hEnv cabal2nix graphviz ];  # NOTE (2)
  };

  # The default Haskell environment, i.e. what you get by calling `mkEnv`
  # with no extra packages.
  defaultEnv = mkEnv [];

}
# NOTE
# ----
# 1. Haskell broken packages. See:
# - https://github.com/c0c0n3/nixie/issues/1
# 2. Graphviz. diagrams-graphviz needs it so we install it in the env.
# It's one hell of a useful program to have at your fingertips to draw
# graphs, especially in combination with the Diagrams lib.
