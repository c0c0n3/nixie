#
# A fairly complete TeX environment but still as lightweight as possible.
# The idea is to get an environment where I can happily write most LaTeX docs
# without having to worry about installing common packages, but at the same
# time without bloating the Nix store with GBs of packages I'll never actually
# use---either as a direct or indirect LaTeX dependency. Tex docs aren't
# included either since I never actually use local docs, rather I Google for
# answers. Keep in mind if you need to add extras not included in the default
# set of packages provided here, you can still do that---see below.
#
# So what's in the box? Basically everything in the Nixpkgs `scheme-full`
# except for:
#
# - collection-context
# - collection-fontsextra
# - collection-games
# - collection-humanities
# - collection-lang* (but collection-langenglish is in)
# - collection-music
# - collection-texworks
# - collection-xetex
#
# Okay, but how much space am I saving? Well, `defaultEnv` (see below) eats
# up about 1.8G of your disk. In comparison, Nixpkgs `scheme-medium` takes
# about 1.6G whereas `scheme-full` needs a whooping 4.5G. Keep in mind these
# are quick & dirty figures I got for each derivation by running `du -hs /nix`
# on a clean-slate Nix store (i.e. what you get after installing Nix), then
# getting a Nix shell for the derivation and finally running `du` again to
# see how much bigger the Nix store grew. Surely YMMV.
#
# NOTE
# 1. XeTeX. It isn't there since these days it looks like LuaTeX (included)
# can do whatever XeTex can and even better---well, except for using fonts
# installed on your system, outside of the LaTeX environment.
# 2. Fonts. While we include all the recommended LaTeX fonts, we leave out
# the ones in the `fontsextra` collection. This saves about 2GB of space.
# If you need a font from `fontsextra`, just pass it in as an extra package
# when calling `mkEnv`---see below.
#
{ pkgs, ... }:
rec {

  # The default set of packages included in our TeX environment.
  basePkgs = with pkgs; {
    inherit (texlive)
      collection-basic
      collection-bibtexextra
      collection-binextra
      collection-fontsrecommended
      collection-fontutils
      collection-formatsextra
      collection-langenglish
      collection-latex
      collection-latexextra
      collection-latexrecommended
      collection-luatex
      collection-mathscience
      collection-metapost
      collection-pictures
      collection-plaingeneric
      collection-pstricks
      collection-publishers
    ;
  };

  # Build a Tex environment containing the base packages plus any extras
  # given in the argument. E.g.
  #
  #     extraPkgSet = with pkgs; { inherit (texlive) fontawesome; };
  #     myLatex = mkEnv extraPkgSet;
  #
  # This function returns a derivation for the TeX environment.
  #
  mkEnv = extraPkgSet: pkgs.texlive.combine ({
      pkgFilter = pkg: pkg.tlType == "run" || pkg.tlType == "bin";  # (*)
    } // basePkgs // extraPkgSet);
  # NOTE. Filtering out doc derivation outputs by not including "doc" type.

  # A TeX environment containing the base packages plus some hand-picked
  # fonts from collection-fontsextra. These are the fonts that I've been
  # using in my LaTeX docs that aren't included in the base TeX fonts.
  defaultEnv = let
    extraFonts = with pkgs; {
      inherit (texlive)
        alegreya
        eulervm
        fontawesome
        iwona
        sourcecodepro;
    };
  in
    mkEnv extraFonts;

}
