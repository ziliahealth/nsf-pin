{ pkgsFallback
, mkSrcHelpersWLocalFilter
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
  # An already resolved attrset of pinned srcs where key
  # is the src's name and value is the channel attr set (
  # `{default = {name = ..; version = ..; src = ..}; other = ..;}`)
  # This is optional.
, pinned ? {}
} @ args:

let
  optionalAttrs = cond: as: if cond then as else {};
  ensureListWhenStrOrList = x:
    if builtins.isList x
      then x
    else
      assert builtins.isString x;
      [ x ];

  nix-gitignore =
    if null != pkgs
      then pkgs.nix-gitignore
    else
      # TODO: Consider an alternative gitignore solution
      # as downloading a pinned versions of nixpkgs just
      # to get this package is might seem quite costly.
        let
          pkgs = (import (../.nix) {}).ensurePkgs {};
        in
      pkgs.nix-gitignore;
in

mkSrcHelpersWLocalFilter ({
    inherit pinnedSrcsDir workspaceDir pkgs pinned;
    localSrcFilter = pname: localSrc: pinnedSrc:
      nix-gitignore.gitignoreSourcePure (
          if srcPureIgnores ? "${pname}"
            then
              ensureListWhenStrOrList srcPureIgnores."${pname}"
          else if srcPureIgnores ? "default"
            then ensureListWhenStrOrList
              srcPureIgnores.default
          else
            []
        )
        localSrc;
  })
