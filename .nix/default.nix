{ pkgs ? null
, workspaceDir ? null
}:

# When `pkgs == null`, the drawbacks are:
#  -  `nsf-pin` cli tools are not available.
#  -  A pin's `default.nix` file won't be able to receive packages
#     from `pkgs` as input.
# Usually, one should set pkgs to null only when pinning `nixpkgs`
# itself or when one want to avoid using `nixpkgs`.

# When non null, should be a path or if a string, an absolute path.
assert null == workspaceDir
  || (builtins.isPath workspaceDir)
  || ("/" == builtins.substring 0 1 workspaceDir);

let
  pinnedSrcsDir = ./pinned-src;
  nsfp = rec {
    srcPath = ../.;
    nixLib = (import (srcPath + "/release.nix") { inherit pkgs; }).nix-lib;
  };
in

rec {
  srcs = nsfp.nixLib.mkSrcDir {
    inherit pinnedSrcsDir;
    inherit workspaceDir;
    srcPureIgnores = {};
    inherit pkgs;
  };

  # TODO: Develop this idea. A nice approach would be to take
  # some (non version controlled config file) as input to make
  # a proper channel selection. Would also allow user to control
  # the location of local source files and whether local sources
  # are allowed.
  pickedSrcs =
    builtins.mapAttrs (k: v: v.default) srcs.pinned;

  importPkgs = { nixpkgs ? null } @ args:
      let
        nixpkgs =
          if args ? "nixpkgs" && null != args.nixpkgs
            then args.nixpkgs
            # This constitutes our default nixpkgs.
            else pickedSrcs.nixpkgs.src;
      in
    assert null != nixpkgs;
    import nixpkgs { inherit overlays; };

  ensurePkgs = { pkgs ? null, nixpkgs ? null }:
    if null != pkgs
      then pkgs
    else
      importPkgs { inherit nixpkgs; };
}
