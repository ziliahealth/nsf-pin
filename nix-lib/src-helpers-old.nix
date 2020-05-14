{ pinnedSrcHelpers
, pkgsFallback
}:
{
  # Where to find the per src channels (e.g.: ../pinned-src).
  pinnedSrcsDir
  # Where to find the dependencies / other local repos.
  # Usually alongside this repository. Default to null.
  # When `null`, the *local* helpers won't be available.
, workspaceDir
  # A filter allowing custom removal of local src files.
  # Identity filter by default.
, localSrcFilter ? pname: localSrc: pinnedSrc: localSrc
  # Optional package set in case the pinned channel helpers
  # requires some dependencies. By default / for most uses,
  # it shouldn't.
, pkgs ? pkgsFallback
  # A already resolved attrset of pinned srcs where key
  # is the src's name and value is the channel attr set (
  # `{default = {name = ..; version = ..; src = ..}; other = ..;}`)
  # This is optional.
, pinned ? {}
}:

with pinnedSrcHelpers;

let
  optionalAttrs = cond: as: if cond then as else {};
in

rec {
  #
  # Backward compatibility interface.
  #
  getPinnedSrcExt = pname:
        { channel ? "default"}:
      let
        pinnedSrc = fetchPinnedSrc (pinnedSrcsDir + "/${pname}");
        pinnedChannel =
          if pinnedSrc ? "${channel}"
            then channel.channel
          else
            assert pinnedSrc ? "default";
            channel.default;
      in
    pinnedChannel;

  getPinnedSrc = pname: getPinnedSrcExt pname {};
  getRawLocalOrPinnedSrc = getPinnedSrc;
  getLocalOrPinnedSrc = getPinnedSrc;

  # Default behavior for when ws dir is unknown / unavailable.
  existLocalSrc = false;
  # We fallback on always retrieving the pinned version.
  fetchRawLocalOrPinnedSrc = fetchPinnedSrc;
  fetchLocalOrPinnedSrc = fetchPinnedSrc;
} // optionalAttrs (workspaceDir != null) rec {
  /*
    The following are only available when a workspace directory is specified.
    Basically, `getLocalOrPinnedSrc` allow one to retrieve the a local
    version of the src under the specified workspace directory fallbacking on the
    pinned version if the local one does no exists.
  */
  existLocalSrc = pname:
      let
        localSrc = workspaceDir + "/${pname}";
      in
    builtins.pathExists localSrc;

  getRawLocalOrPinnedSrc = pname:
      let
        localSrc = workspaceDir + "/${pname}";
        pinnedSrc = getPinnedSrc pname;
        rawLocalSrc = rec {
          src = localSrc;
          version = {
            type = "local";
            url = builtins.toString localSrc;
          };
        };
      in
    if (existLocalSrc pname) then rawLocalSrc else pinnedSrc;

  getLocalOrPinnedSrc = pname:
      let
        localSrc = workspaceDir + "/${pname}";
        pinnedSrc = getPinnedSrc pname;
        filteredLocalSrc = rec {
          src =
            localSrcFilter pname localSrc pinnedSrc.src;
          version = {
            type = "local";
            url = builtins.toString localSrc;
          };
        };
      in
    if (existLocalSrc pname) then filteredLocalSrc else pinnedSrc;
}
