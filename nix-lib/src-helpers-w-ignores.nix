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
in

mkSrcHelpersWLocalFilter ({
    inherit pinnedSrcsDir workspaceDir pkgs pinned;
  # A local source filter is only provided when
  # a `pkgs` set is available. This is because
  # we need the package `nix-gitignore`.
  # TODO: We might be able to provide some alternative for that
  #       (alternative ignore lib?).
  } // optionalAttrs (null != pkgs) {
    localSrcFilter = pname: localSrc: pinnedSrc:
      pkgs.nix-gitignore.gitignoreSourcePure (
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
