{}:

let
  defOpts =
    {
      channelDirName = "channel";
      pkgs = null;
    };

  listDirSubDirs = dirPath:
    assert builtins.isPath dirPath;
    builtins.map (x: dirPath + "/${x}") (
      builtins.filter (x: null != x) (
        builtins.attrValues (
          builtins.mapAttrs (k: v: if "directory" == v then k else null) (
            builtins.readDir dirPath))));
in

rec {
  fetchGitPinnedChannel = channelSrcInfo:
    let
      fetchGitExpectedAttr = { "url" = null; "ref" = null; "rev" = null; };
      filteredSrcInfo = builtins.intersectAttrs fetchGitExpectedAttr channelSrcInfo;
      src = builtins.fetchGit filteredSrcInfo;
    in {
      inherit src;
      version = {
        type = "git";
        inherit (channelSrcInfo) url ref rev;
      };
    };


  fetchGithubPinnedChannel = channelSrcInfo:
    let
      fetchGitExpectedAttr = { "owner" = null; "repo" = null; "ref" = null; "rev" = null; };
      filteredSrcInfo = builtins.intersectAttrs fetchGitExpectedAttr channelSrcInfo;
      src = builtins.fetchTarball {
        url = "https://github.com/${channelSrcInfo.owner}/${channelSrcInfo.repo}/archive/${channelSrcInfo.rev}.tar.gz";
        sha256 = channelSrcInfo.sha256;
      };
    in {
      inherit src;
      version = {
        type = "git";
        url = "https://github.com/${channelSrcInfo.owner}/${channelSrcInfo.repo}";
        inherit (channelSrcInfo) ref rev;
      };
    };


  fetchPinnedChannelJson = channelJsonPath:
      let
        channelSrcInfo = builtins.fromJSON (builtins.readFile (channelJsonPath));
        channelType = channelSrcInfo.type;

        typeToFetcherFn = {
          "builtins.fetchGit" = fetchGitPinnedChannel;
          "fetchFromGitHub" = fetchGithubPinnedChannel;
        };

        assertFetcherTypeSupported =
          if typeToFetcherFn ? channelType
          then true
          else builtins.trace
            "Pinned channel Fetcher type '${channelType}' is not supported."
            false;

        fetchFn = typeToFetcherFn."${channelType}";

      in
    fetchFn channelSrcInfo;


  fetchPinnedChannels = srcRootDir: channelsDir:
      let
        # The `srcRootDir` is required to improve
        # error messages but also to return a name alongside
        # the `src` and `version attributes.
        srcName = "${baseNameOf (toString srcRootDir)}";
        toChannelNames = bn:
            let
              splitted = builtins.split "^([^\.]+).json$" bn;
            in
          if 3 != builtins.length splitted
            then []
            else builtins.elemAt splitted 1;

        chanelDirContent = (builtins.attrNames (builtins.readDir channelsDir));
        channelNames = builtins.foldl' (acc: bn:  acc ++ toChannelNames bn) [] chanelDirContent;

        channelJsonFileAttrs =
            let
              toNVTuple = cname: {name = cname; value = channelsDir + "/${cname}.json"; };
            in
          builtins.listToAttrs (builtins.map toNVTuple channelNames);

        fetchedChannels =
          builtins.mapAttrs (cname: cjson:
              # As we have it at hand, give the channel a name too.
              fetchPinnedChannelJson cjson // { name = cname; })
            channelJsonFileAttrs;

        assertHasDefaultChannel =
          if fetchedChannels ? "default"
          then true
          else builtins.trace
            "Pinned source '${srcName}' does not expose the mandatory 'default' channel."
            false;
      in
    assert assertHasDefaultChannel;
    # Propagate the src's name.
    # TODO: This seems to be the channel name.
    # IDEA: We should return both: `name = "my-src:my-channel"`.
    fetchedChannels // { name = srcName; };


  fetchPinnedSrc = pinnedSrcDir:
        { channelDirName ? defOpts.channelDirName
        , pkgs ? defOpts.pkgs} @ args:
      let
        pkgs =
          if args ? "pkgs" && null != args.pkgs
            then args.pkgs
          else
            {};

        callFnWith = autoArgs: fn: args:
          let
            f = if builtins.isFunction fn then fn else (import fn);
            auto = builtins.intersectAttrs (builtins.functionArgs f) autoArgs;
          in (f (auto // args));

        callFn = callFnWith pkgs;

        customChannelsDefPath = (pinnedSrcDir + "/default.nix");
      in
    if builtins.pathExists customChannelsDefPath
      then callFn customChannelsDefPath {}
    else
      fetchPinnedChannels
        pinnedSrcDir
        (pinnedSrcDir + "/${channelDirName}");


  listAllPinnedSrcPaths = pinnedSrcsDir:
    (listDirSubDirs pinnedSrcsDir);


  listAllPinnedSrcNames = pinnedSrcsDir:
    map (x: builtins.baseNameOf x) (listAllPinnedSrcPaths pinnedSrcsDir);


  attrsAllPinnedSrcPaths = pinnedSrcsDir:
    builtins.listToAttrs (
        map (x:
            {
              name = builtins.baseNameOf x;
              value = x;
            })
        (listAllPinnedSrcPaths pinnedSrcsDir)
      );


  fetchAllPinnedSrcs = pinnedSrcsDir: opts:
    builtins.mapAttrs (k: v:
        fetchPinnedSrc v opts
      )
      (attrsAllPinnedSrcPaths pinnedSrcsDir);
}
