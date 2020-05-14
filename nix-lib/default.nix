{ pkgs ? null }:

rec {
  pinnedSrcHelpers = import ./pinned-src-helpers.nix {};

  mkSrcHelpersWLocalFilter = import ./src-helpers.nix {
    inherit pinnedSrcHelpers;
    pkgsFallback = pkgs;
  };

  # The w local filter is the default one as the most generic.
  mkSrcHelpers = mkSrcHelpersWLocalFilter;

  mkSrcHelpersWLocalIgnores = import ./src-helpers-w-ignores.nix {
    inherit mkSrcHelpersWLocalFilter;
    pkgsFallback = pkgs;
  };

  mkSrcDir = import ./src-dir.nix {
    inherit pinnedSrcHelpers;
    inherit mkSrcHelpersWLocalIgnores;
    pkgsFallback = pkgs;
  };

  #
  # Backward compat interface.
  #
  mkSrcHelpersWLocalFilterOld = import ./src-helpers-old.nix {
    inherit pinnedSrcHelpers;
    pkgsFallback = pkgs;
  };

  mkSrcHelpersOld = mkSrcHelpersWLocalFilterOld;
}

