Readme
======

A simple nix repository pin system.

Currently used as part of [nixos-secure-factory], hence the `nsf-` prefix.
However, this can perfectly be used as a standalone library / tool.

[nixos-secure-factory]: https://github.com/jraygauthier/nixos-secure-factory


Todo
----

 -  Make sure that sources from `localOrPinned` get access to their own local sources.

    This is because those sources are filtered which make them end in the
    nix store where there isn't any of the sources. One simple way would
    be to create some kind of symlink forest in the store before returning
    the path so that proper files are found.

    In the meantime, if this is deemed essential, one can use instead the
    unfiltered sources `rawLocalOrPinned`.


Contributing
------------

Contributing implies licensing those contributions under the terms of [LICENSE](./LICENSE), which is an *Apache 2.0* license.
