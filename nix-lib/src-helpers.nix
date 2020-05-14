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

let
  optionalAttrs = cond: as: if cond then as else {};
  pinnedApi = {
    fetchPinnedSrc = pname: opts:
      if pinned ? "${pname}"
        then pinned."${pname}"
      else
        pinnedSrcHelpers.fetchPinnedSrc (pinnedSrcsDir + "/${pname}") opts;
    listAllPinnedSrcPaths =
      pinnedSrcHelpers.listAllPinnedSrcPaths pinnedSrcsDir
        # TODO: Consider deep overrides instead so that a user can
        # override on a per channel basis.
        // pinned;
    listAllPinnedSrcNames =
      pinnedSrcHelpers.listAllPinnedSrcNames pinnedSrcsDir;
    attrsAllPinnedSrcPaths =
      pinnedSrcHelpers.attrsAllPinnedSrcPaths pinnedSrcsDir;
    fetchAllPinnedSrcs = opts:
      pinnedSrcHelpers.fetchAllPinnedSrcs pinnedSrcsDir opts;
  };
in

with pinnedApi;

pinnedApi // {
  # Default behavior for when ws dir is unknown / unavailable.
  existLocalSrc = false;
  # We fallback on always retrieving the pinned version.
  fetchRawLocalOrPinnedSrc = fetchPinnedSrc;
  fetchLocalOrPinnedSrc = fetchPinnedSrc;
  fetchAllRawLocalOrPinnedSrcs = fetchAllPinnedSrcs;
  fetchAllLocalOrPinnedSrcs = fetchAllPinnedSrcs;

} // optionalAttrs (workspaceDir != null) rec {
  /*
    The following are only available when a workspace directory is specified.
    Basically, `fetchLocalOrPinnedSrc` allow one to retrieve the a local
    version of the src under the specified workspace directory fallbacking on the
    pinned version if the local one does no exists.
  */
  existLocalSrc = pname:
      let
        localSrc = workspaceDir + "/${pname}";
      in
    builtins.pathExists localSrc;

  fetchRawLocalOrPinnedSrc = pname: opts:
      let
        localSrc = workspaceDir + "/${pname}";
        pinnedSrc = fetchPinnedSrc pname opts;
        rawLocalSrc = rec {
          # TODO: For the time being, we only support the default
          # channel for local source. Some options might be
          # read for a branch mapping at some point.
          default = {
            name = pname;
            src = localSrc;
            version = {
              type = "local";
              url = builtins.toString localSrc;
            };
          };
        };
      in
    if (existLocalSrc pname) then rawLocalSrc else pinnedSrc;

  fetchLocalOrPinnedSrc = pname: opts:
      let
        localSrc = workspaceDir + "/${pname}";
        pinnedSrc = fetchPinnedSrc pname opts;
        filteredLocalSrc = rec {
          # TODO: For the time being, we only support the default
          # channel for local source. Some options might be
          # read for a branch mapping at some point.
          default = {
            name = pname;
            src =
              localSrcFilter pname localSrc pinnedSrc.default.src;
            version = {
              type = "local";
              url = builtins.toString localSrc;
            };
          };
        };
      in
    if (existLocalSrc pname) then filteredLocalSrc else pinnedSrc;


  fetchAllRawLocalOrPinnedSrcs = opts: builtins.mapAttrs (k: v:
      fetchRawLocalOrPinnedSrc k opts
    )
    attrsAllPinnedSrcPaths;

  fetchAllLocalOrPinnedSrcs = opts: builtins.mapAttrs (k: v:
      fetchLocalOrPinnedSrc k opts
    )
    attrsAllPinnedSrcPaths;
}
