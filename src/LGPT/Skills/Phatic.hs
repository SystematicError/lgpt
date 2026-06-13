module LGPT.Skills.Phatic (parser, help) where

-- Reply to phatic requests
-- https://en.wikipedia.org/wiki/Phatic_expression

import Control.Monad (void)
import LGPT.Grammar
import LGPT.Helpers (printSkillHelp)
import System.Exit (exitSuccess)
import Text.Megaparsec

help :: IO ()
help =
  printSkillHelp
    "Phatic"
    "Reply to phatic requests."
    [ ("[OPENING]", "Greet the user back"),
      ("[CLOSING]", "Say bye and halt the REPL"),
      ("[FILLER]", "Give a generic reply back")
    ]
    [ "Hello.",
      "Goodbye, thank you!",
      "Oh wow - I see that... it makes so much more sense now!"
    ]

data Phatic = Opening | Closing | Filler

parseOpening :: Parser Phatic
parseOpening = do
  some $
    phraseChoice
      [ "hi",
        "hey",
        "hello",
        "yo",
        "greetings"
      ]

  pure Opening

parseClosing :: Parser Phatic
parseClosing = do
  some $
    phraseChoice
      [ "bye",
        "goodbye",
        "thanks",
        "thank you",
        "see you",
        "farewell"
      ]

  pure Closing

parseExcalamation :: Parser ()
parseExcalamation =
  void $
    phraseChoice
      [ "wow",
        "whoa",
        "yay",
        "yippee",
        "holy cow",
        "oh my god",
        "dang",
        "damn",
        "no way"
      ]

parseRealisation :: Parser ()
parseRealisation =
  choice
    [ void $ word "oh",
      void $ word "ah",
      -- i see (it|that)? now?
      void $ do
        phrase "i see"
        optional $ wordChoice ["it", "that"]
        optional $ word "now",
      void $ do
        -- (it|that)? makes ((so much|way|even)? more)? sense now?
        optional $ wordChoice ["it", "that"]
        word "makes"
        optional $ do
          optional $ do
            optional $ phraseChoice ["so much", "way", "even"]
          word "more"
        word "sense"
        optional $ word "now"
    ]

-- Filler phrases are a mixture of exclamations and realisations
parseFiller :: Parser Phatic
parseFiller = do
  some $ parseExcalamation <|> parseRealisation
  pure Filler

parsePhatic :: Parser Phatic
parsePhatic = choice [parseOpening, parseClosing, parseFiller]

parser :: Parser (IO ())
parser = request $ do
  phatic <- parsePhatic

  pure $ case phatic of
    Opening -> putStrLn "Hi there!"
    Closing -> putStrLn "Goodbye!" >> exitSuccess
    Filler -> putStrLn "Hope I was of help!"
