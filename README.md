Marvin
======

this is a small package for paranoid testing in Haskell,
as described in http://www.shimweasel.com/2015/04/06/paranoid-testing-in-haskell/

usage: in your cabal directory, first run "cabal freeze" so we have a
consistent set of packages to use. Then run "marvin", with an optional list of packages not to build.
Marvin will then spit out an inordinate amount of text, finishing up with a quick precis of which
dependencies built in-context and which didn't. This is still rough as guts.
