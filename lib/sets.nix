#
# Utils to work with sets.
# This is a function that takes the Nixpkgs lib as input and returns a set
# with the utils.
#
nixlib: rec
{
  # merge :: set -> set -> set
  #
  # Alias for Nixpkgs `recursiveUpdate` in `lib/attrsets.nix`.
  # Notice this function merges set attributes recursively, stopping
  # recursion if an attribute isn't a set. So if two non-set attributes
  # have the same path both in the lhs and rhs, then the rhs one overrides
  # the lhs one in the result.
  #
  # Example (from Nixpkgs docs):
  #
  #    mergeSets {
  #       boot.loader.grub.enable = true;
  #       boot.loader.grub.device = "/dev/hda";
  #     } {
  #       boot.loader.grub.device = "";
  #     }
  #
  # returns:
  #
  #   {
  #     boot.loader.grub.enable = true;
  #     boot.loader.grub.device = "";
  #   }
  #
  # For a variation on the theme that can merge arrays too, see
  # - https://stackoverflow.com/questions/54504685
  #
  merge = nixlib.recursiveUpdate;

  # mergeAll :: [set] -> set
  #
  # Like `merge` but it accepts a list of sets as input.
  mergeAll = with builtins; foldl' merge {};

  # mergeAttr :: str -> [set] -> set
  #
  # Merge all `attrName` set values found in the input sets. Ignore any input
  # set that doesn't contain `attrName` and also ignore any `attrName` that
  # isn't itself a set.
  mergeAttr = attrName: sets:
  with builtins;
  let
    isTarget = set: set ? ${attrName} && isAttrs set.${attrName};
    targets = map (s: s.${attrName}) (filter isTarget sets);
  in
    mergeAll targets;

  # cartProd :: [set] -> [set] -> [set]
  #
  # Given two lists of sets `xs` and `ys`, return the list
  #
  #     [ merge x y | x ∈ xs, y ∈ ys ]
  #
  # Example:
  #
  #   cartProd [ { x1 = 1; } { x2 = 2; } ]
  #            [ { y1 = 1; } { y2 = 2;} { y3 = 3;} ]
  #   ~~>
  #       [ { x1 = 1; y1 = 1; } { x2 = 2; y1 = 1; }
  #         { x1 = 1; y2 = 2; } { x2 = 2; y2 = 2; }
  #         { x1 = 1; y3 = 3; } { x2 = 2; y3 = 3; } ]
  #
  cartProd = xs: ys:
  with builtins;
  let
    mergeY = y: map (x: merge x y) xs;
  in
    concatMap mergeY ys;

}
