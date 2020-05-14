MKF_CWD := $(shell pwd)

.PHONY: all clean release

all: release

clean:
	rm -f ./result*

release:
	nix-build release.nix --arg pkgs 'import <nixpkgs> {}' -A cli

	nix eval --show-trace --raw \
	  '(builtins.toString (builtins.isAttrs ((import ./release.nix {}).nix-lib.srcHelpers)))'

	nix eval --show-trace --raw \
	  '(builtins.toString (builtins.isAttrs ((import ./release.nix {}).nix-lib.pinnedSrcHelpers)))'

	nix eval --show-trace --raw \
	  '(builtins.toString (builtins.isAttrs ((import ./release.nix {}).nix-lib.mkSrcDir)))'

