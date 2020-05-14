{ pkgsFallback
, pinnedSrcHelpers
, mkSrcHelpersWLocalIgnores
}:
{
  # Where to find the per src channels (e.g.: ../pinned-src).
  pinnedSrcsDir
  # Where to find the dependencies / other local repos.
  # Usually alongside this repository. Default to null.
  # When `null`, the *local* helpers won't be available.
, workspaceDir
  # Ignored files when using the local (workspace)
  # version of the src.
  # An attribute set with package names as key and
  # either a string or a list as value with the ignores
  # (as expected by `pkgs.nix-gitignore.gitignoreSourcePure`).
  # A attribute with the `default` key means these ignores
  # should be applied to all local sources.
, srcPureIgnores ? {}
  # Optional package set in case the pinned channel helpers
  # requires some dependencies. By default / for most uses,
  # it shouldn't.
, pkgs ? pkgsFallback

  # The directory were to look for a pinned src's channels.
, channelDirName ? "channel"
} @ args:

let
  opts = {
    inherit pkgs;
    inherit channelDirName;
  };
in

rec {
  helpersPinned = pinnedSrcHelpers;
  helpers = mkSrcHelpersWLocalIgnores {
    inherit workspaceDir pinnedSrcsDir srcPureIgnores pinned pkgs;
  };

  inherit srcPureIgnores;

  pinnedPaths = helpers.attrsAllPinnedSrcPaths;
  pinned = helpers.fetchAllPinnedSrcs opts;
  rawLocalOrPinned = helpers.fetchAllRawLocalOrPinnedSrcs opts;
  localOrPinned = helpers.fetchAllLocalOrPinnedSrcs opts;
}
