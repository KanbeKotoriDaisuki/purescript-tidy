module Bin.FormatOptions where

import Prelude

import ArgParse.Basic (ArgParser)
import ArgParse.Basic as Arg
import Control.Alt ((<|>))
import Control.Monad.Error.Class (throwError)
import Data.Argonaut.Core (Json, jsonEmptyObject, jsonNull)
import Data.Argonaut.Core as Json
import Data.Argonaut.Decode (JsonDecodeError(..), decodeJson, (.:?))
import Data.Argonaut.Encode (assoc, encodeJson, extend)
import Data.Either (Either)
import Data.Maybe (Maybe(..), fromMaybe, maybe)
import Data.Traversable (traverse)
import PureScript.CST.Tidy (TypeArrowOption(..), UnicodeOption(..))

type FormatOptions =
  { indent :: Int
  , operatorsFile :: Maybe String
  , ribbon :: Number
  , typeArrowPlacement :: TypeArrowOption
  , unicode :: UnicodeOption
  , width :: Maybe Int
  }

defaults :: FormatOptions
defaults =
  { indent: 2
  , operatorsFile: Nothing
  , ribbon: 1.0
  , typeArrowPlacement: TypeArrowFirst
  , unicode: UnicodeSource
  , width: Nothing
  }

formatOptions :: ArgParser FormatOptions
formatOptions =
  Arg.fromRecord
    { indent:
        Arg.argument [ "--indent", "-i" ]
          "Number of spaces to use as indentation.\nDefaults to 2."
          # Arg.int
          # Arg.default defaults.indent
    , operatorsFile:
        Arg.argument [ "--operators", "-o" ]
          "Path to an operator table generated by `generate-operators`.\nDefault is to use a pre-generated table of core and contrib."
          # Arg.unformat "FILE_PATH" pure
          # Arg.optional
    , ribbon:
        Arg.argument [ "--ribbon", "-r" ]
          "The ratio of printable width to maximum width.\nFrom 0 to 1. Defaults to 1."
          # Arg.number
          # Arg.default defaults.ribbon
    , typeArrowPlacement:
        Arg.choose "type arrow placement"
          [ Arg.flag [ "--arrow-first", "-af" ]
              "Type signatures put arrows first on the line.\nDefault."
              $> TypeArrowFirst
          , Arg.flag [ "--arrow-last", "-al" ]
              "Type signatures put arrows last on the line."
              $> TypeArrowLast
          ]
          # Arg.default defaults.typeArrowPlacement
    , unicode: unicodeOption
    , width:
        Arg.argument [ "--width", "-w" ]
          "The maximum width of the document in columns.\nDefaults to no maximum."
          # Arg.int
          # Arg.optional
    }

unicodeOption :: ArgParser UnicodeOption
unicodeOption =
  Arg.choose "unicode argument"
    [ Arg.flag [ "--unicode-source", "-us" ]
        "Unicode punctuation is rendered as it appears in the source input.\nDefault."
        $> UnicodeSource
    , Arg.flag [ "--unicode-always", "-ua" ]
        "Unicode punctuation is always preferred."
        $> UnicodeAlways
    , Arg.flag [ "--unicode-never", "-un" ]
        "Unicode punctuation is never preferred."
        $> UnicodeNever
    ]
    # Arg.default defaults.unicode

fromJson :: Json -> Either JsonDecodeError FormatOptions
fromJson json = do
  obj <- decodeJson json
  indent <- obj .:? "indent"
  operatorsFile <- obj .:? "operatorsFile"
  ribbon <- obj .:? "ribbon"
  typeArrowPlacement <- traverse typeArrowPlacementFromString =<< obj .:? "typeArrowPlacement"
  unicode <- traverse unicodeFromString =<< obj .:? "unicode"
  width <- obj .:? "width"
  pure
    { indent: fromMaybe defaults.indent indent
    , operatorsFile: operatorsFile <|> defaults.operatorsFile
    , ribbon: fromMaybe defaults.ribbon ribbon
    , typeArrowPlacement: fromMaybe defaults.typeArrowPlacement typeArrowPlacement
    , unicode: fromMaybe defaults.unicode unicode
    , width: width <|> defaults.width
    }

toJson :: FormatOptions -> Json
toJson options =
  jsonEmptyObject
    # extend (assoc "indent" options.indent)
    # extend (assoc "operatorsFile" (maybe jsonNull encodeJson options.operatorsFile))
    # extend (assoc "ribbon" options.ribbon)
    # extend (assoc "typeArrowPlacement" (typeArrowPlacementToString options.typeArrowPlacement))
    # extend (assoc "unicode" (unicodeToString options.unicode))
    # extend (assoc "width" (maybe jsonNull encodeJson options.width))

typeArrowPlacementFromString :: String -> Either JsonDecodeError TypeArrowOption
typeArrowPlacementFromString = case _ of
  "first" -> pure TypeArrowFirst
  "last" -> pure TypeArrowLast
  other -> throwError $ UnexpectedValue (Json.fromString other)

typeArrowPlacementToString :: TypeArrowOption -> String
typeArrowPlacementToString = case _ of
  TypeArrowFirst -> "first"
  TypeArrowLast -> "last"

unicodeFromString :: String -> Either JsonDecodeError UnicodeOption
unicodeFromString = case _ of
  "source" -> pure UnicodeSource
  "always" -> pure UnicodeAlways
  "never" -> pure UnicodeNever
  other -> throwError $ UnexpectedValue (Json.fromString other)

unicodeToString :: UnicodeOption -> String
unicodeToString = case _ of
  UnicodeSource -> "source"
  UnicodeAlways -> "always"
  UnicodeNever -> "never"
