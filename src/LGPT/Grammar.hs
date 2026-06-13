module LGPT.Grammar where

-- Core building blocks for constructing parsers

import Control.Monad (void)
import Control.Monad.State
import Data.Void (Void)
import LGPT.Memory (Memory)
import LGPT.Memory qualified as Memory
import Text.Megaparsec
import Text.Megaparsec.Char
import Text.Megaparsec.Char.Lexer qualified as L

-- Parser type wrapper with memory and IO
-- The inclusion of IO allows for complex parser behaviour
-- However, use `liftIO` only where absolutely necessary
type Parser = ParsecT Void String (StateT Memory IO)

-- Spaces and non terminating punctuation that the parser should skip
whitespace :: Parser ()
whitespace = do
  hspace
  optional $ void (oneOf ",-:;") <|> void (string "...")
  hspace

-- Punctuation indicating the end of a sentence
terminalPunctuation :: Parser ()
terminalPunctuation =
  choice
    [ void $ string "...",
      void $ char '.',
      skipSome $ oneOf "!?"
    ]

-- Parses a word (case insensitive) and skips any trailing whitespace
word :: String -> Parser String
word = L.symbol' whitespace

-- Sequences of words
phrase :: String -> Parser [String]
phrase p = try $ mapM word (words p)

-- Run a given parser and skip any trailing whitespace
lexeme :: Parser a -> Parser a
lexeme = L.lexeme whitespace

-- Shorthand for a choice from a list of words
wordChoice :: [String] -> Parser String
wordChoice ws = choice $ map word ws

-- Shorthand for a choice from a list of phrases
phraseChoice :: [String] -> Parser [String]
phraseChoice ps = choice $ map phrase ps

-- Alternative to choice that backtracks on failure
tryChoice :: [Parser a] -> Parser a
tryChoice ps = choice $ map try ps

-- Try to recall the previous evaluation, fail if there is none
that :: Parser String
that = do
  word "that"

  maybeThat <- Memory.recall "that"

  case maybeThat of
    Nothing -> fail "I haven't evaluated anything yet."
    Just result -> pure result

-- Get a literal string between quotes, with character escaping
quoted :: Parser String
quoted = lexeme $ do
  char '"'
  str <- many $ choice [char '\\' >> anySingle, anySingleBut '"']
  char '"'

  pure str

-- Collect words until a given ending parser is matched
entity' :: Parser a -> Parser String
entity' end = do
  let entityChar = alphaNumChar <|> char '\''
  ws <- someTill (lexeme $ some entityChar) end

  pure $ unwords ws

entity :: Parser a -> Parser String
entity end = tryChoice [quoted, entity' end]

-- `quoted`, `entity'` and `entity` are used to parse in arbitrary strings
--
-- `quoted` parses in literal strings
-- Eg: `Hello,    World...` -> `Hello, World...`
--
-- `entity'` parses in natural language phrases, punctuation and whitespace is normalised
-- Eg: `Hello,    World...` -> `Hello World`
--
-- `entity` provides the best of both worlds

-- Marks the end of a request
-- Useful in combination with `entity`
requestEnd :: Parser ()
requestEnd = do
  optional terminalPunctuation
  hspace
  eof

-- Polite prefixes to requests (that doesn't impact its semantics)
politenessMarker :: Parser ()
politenessMarker = do
  optional $ word "please"
  void $ optional $ phraseChoice ["can you", "could you"]

-- Handles the structure of a complete user request
request :: Parser a -> Parser a
request parser = do
  hspace
  politenessMarker
  p <- parser
  requestEnd

  pure p
