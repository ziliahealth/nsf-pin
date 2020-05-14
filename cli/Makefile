MKF_CWD := $(shell pwd)

.PHONY: all clean release typechecks tests lint

all: typechecks lint release

clean:
	rm -f ./result*

typechecks:
	mypy . $(shell find ./tests -name "test_*.py")

tests:
	pytest

lint: lint-shell lint-python

lint-python:
	flake8

lint-shell:
	shellcheck -x -P \
	  "$(shell nsf-pin-update)" \
	  $(shell find ./sh-lib -type f -name "*.sh") \
	  $(shell find ./bin -mindepth 1 -executable -type f)

release:
	nix-build release.nix -A default

shell-installed:
	nix-shell release.nix -A shell.installed

shell-dev:
	nix-shell release.nix -A shell.dev
