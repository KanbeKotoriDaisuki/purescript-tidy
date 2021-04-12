{ name = "purescript-tidy-cli"
, dependencies =
  [ "aff"
  , "argparse-basic"
  , "arrays"
  , "console"
  , "dodo-printer"
  , "effect"
  , "either"
  , "foldable-traversable"
  , "lists"
  , "maybe"
  , "newtype"
  , "node-buffer"
  , "node-fs"
  , "node-fs-aff"
  , "node-glob-basic"
  , "node-path"
  , "node-process"
  , "node-streams"
  , "node-workerbees"
  , "ordered-collections"
  , "parallel"
  , "partial"
  , "prelude"
  , "psci-support"
  , "purescript-language-cst-parser"
  , "refs"
  , "strings"
  , "tuples"
  ]
, packages = ../packages.dhall
, sources = [ "src/**/*.purs", "bin/**/*.purs" ]
}
