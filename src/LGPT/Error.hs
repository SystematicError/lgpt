module LGPT.Error (handleErrorBundle) where

-- Handles parser errors and tries to offer help where possible

{-
Package Justification
---------------------
text-metrics
    - Easy to use and efficient implementation of the Damerau-Levenshtein algorithm
    - More modern compared to edit-distance

snowball
    - Bindings for snowball, which is an industry standard Porter2 implementation
    - Successor to the stemmer library (also snowball bindings)
    - Other haskell stemming libraries are relatively quite lacking
-}

import Control.Monad (guard)
import Data.Char (isAlpha, toLower)
import Data.List (intercalate, minimumBy)
import Data.List.NonEmpty qualified as NE
import Data.Ord (Down (..), comparing)
import Data.Set (Set)
import Data.Set qualified as Set
import Data.Text qualified as Text
import Data.Text.Metrics (damerauLevenshtein)
import Data.Void (Void)
import LGPT.Grammar
import NLP.Snowball (Algorithm (..), stem)
import System.Console.ANSI
import Text.Megaparsec.Error

-- Error types specialised to the stream and error components of `Parser`
type ErrorItem' = ErrorItem Char
type ParseError' = ParseError String Void
type ParseErrorBundle' = ParseErrorBundle String Void

printBaseMessage :: IO ()
printBaseMessage = putStrLn "I don't understand that."

-- Format and print help text
printHelp :: [String] -> IO ()
printHelp strs = do
  setSGR [SetColor Foreground Dull White]
  mapM_ putStr (strs ++ ["\n"])
  setSGR [Reset]

-- Compare the similarity of two strings using Damerau-Levenshtein distance
-- A lower distance means the strings are more similar
distance :: String -> String -> Int
distance s1 s2 = damerauLevenshtein (normalise s1) (normalise s2)
  where
    -- Make strings lowercase and stem the word using the Porter2 algorithm
    normalise = stem English . Text.pack . map toLower

-- Suggest a replacement when an error is occured, particularly effective for typos
generateSuggestion :: String -> [String] -> Maybe (String, String)
generateSuggestion got expected = do
  -- Extract the first word from the `got` tokens
  let word = takeWhile (`notElem` " ,.-:;!?") $ dropWhile (`elem` " ,.-:;!?") got

  guard $ not (null word)
  guard $ not (null expected)

  -- Suggest an expected word with the lowest distance
  let suggestion = minimumBy (comparing (distance word)) expected

  pure (word, suggestion)

-- List of words that were expected
-- Select only `Tokens` with alphabetical characters (ignoring `Label` and `EndOfInput`)
possibleWords :: Set ErrorItem' -> [String]
possibleWords items = filter (any isAlpha) [NE.toList chars | Tokens chars <- Set.toList items]

-- Handle a single parse error
handleError :: ParseError' -> IO ()

-- Pass through messages of errors thrown using `fail`
handleError (FancyError _ errors) =
  case [message | ErrorFail message <- Set.toList errors] of
    [] -> printBaseMessage
    message : _ -> putStrLn message

-- If the parser expects more tokens than the input provided
handleError (TrivialError _ (Just EndOfInput) expected) = printBaseMessage >> help
  where
    -- Provide a list of all possible expected words
    help = case possibleWords expected of
      [] -> pure ()
      [w] ->
        printHelp
          ["The request ended abruptly, expecting ", show w, "."]
      ws ->
        printHelp
          [ "The request ended abruptly, expecting any of the following words: ",
            intercalate ", " (map show ws),
            "."
          ]

-- If the parser got a diferent set of tokens than expected
handleError (TrivialError _ (Just (Tokens got)) expected) = printBaseMessage >> help
  where
    -- Try generating a suggestion
    help = case generateSuggestion (NE.toList got) (possibleWords expected) of
      Nothing -> pure ()
      Just (word, suggestion) ->
        printHelp ["Did you mean ", show suggestion, " instead of ", show word, "?"]

-- Fallback
handleError _ = printBaseMessage

-- Assign a higher priority to `FancyError` over `TrivialErrors`
deriving instance Ord ParseError'

-- Sort bundle errors by priority and then handle the first one
handleErrorBundle :: ParseErrorBundle' -> IO ()
handleErrorBundle = handleError . NE.head . NE.sortWith Down . bundleErrors
