{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  devPython = python3.withPackages (pp: with pp; [
    pytest
    ipython
    mypy
    flake8
  ]);
in

rec {
  default = callPackage ./. {};

  shell = {
    installed = mkShell rec {
      name = "${default.pname}-installed-shell";

      buildInputs = [
        default
      ];
    };

    dev = mkShell rec {
      name = "${default.pname}-dev-shell";

      PYTHONPATH = "";
      MYPYPATH = "";

      inputsFrom = [
        default
      ];

      buildInputs = [
        devPython
        shellcheck
      ];

      shellHook = ''
        export PATH="${builtins.toString ./bin}:$PATH"
        export "PYTHON_INTERPRETER=${devPython}/bin/python"
      '';
    };
  };
}
