{ pkgs ? null }:

let
  nix-lib = import ./nix-lib { inherit pkgs; };
in

{
  inherit nix-lib;
} // (if null == pkgs then {} else {
  cli = (import ./cli/release.nix { inherit pkgs; }).default;
})
