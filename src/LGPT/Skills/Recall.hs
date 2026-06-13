module LGPT.Skills.Recall (parser, help) where

-- Interact directly with the AI's memory

import LGPT.Grammar
import LGPT.Helpers (printSkillHelp)
import LGPT.Memory qualified as Memory
import Text.Megaparsec

help :: IO ()
help =
  printSkillHelp
    "Recall"
    "Interact directly with the AI's memory."
    [ ("Remember that [NAME] is [THING]", "Remember something about a named entity"),
      ("Forget about [NAME]", "Delete information about a named entity"),
      ("Tell me about [NAME]", "Recall information about a named entity")
    ]
    [ "Remember that the sky is blue",
      "Tell me about the sky",
      "Forget about the sky",
      "Tell me about the meaning of life, the universe, and everything"
    ]

data Response
  = Remember
  | Forget
  | RecallFail !String
  | RecallSuccess !String !String

-- Record an entry
parseRemember :: Parser Response
parseRemember = do
  phrase "remember that"
  name <- entity (word "is")
  thing <- entity requestEnd

  Memory.remember name thing

  pure Remember

-- Delete an entry
parseForget :: Parser Response
parseForget = do
  phrase "forget about"
  name <- entity requestEnd

  Memory.forget name

  pure Forget

-- Lookup an entry
parseRecall :: Parser Response
parseRecall = do
  phrase "tell me about"
  name <- entity requestEnd

  maybeThing <- Memory.recall name

  pure $ case maybeThing of
    Nothing -> RecallFail name
    Just thing -> RecallSuccess name thing

parser :: Parser (IO ())
parser = request $ do
  response <- choice [parseRemember, parseForget, parseRecall]

  pure $ putStrLn $ case response of
    Remember -> "Okay."
    Forget -> "Okay."
    RecallFail name -> "Sorry, I don't know anything about " ++ name ++ "."
    RecallSuccess name thing -> "Sure - " ++ name ++ " is " ++ thing ++ "."
