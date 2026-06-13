module LGPT.TUI (runREPL) where

-- Provides a REPL running the AI

{-
Package Justification
---------------------
haskeline - Same interactive line editing library used by GHCI, quite powerful
-}

import Control.Monad.State
import LGPT.Error (handleErrorBundle)
import LGPT.Grammar
import LGPT.Helpers (prompt)
import LGPT.Memory (Memory)
import LGPT.Memory qualified as Memory
import LGPT.Skills
import System.Console.Haskeline
import Text.Megaparsec

-- Creates a top level parser by merging skills
parseRequest :: Parser (IO ())
parseRequest =
  mergeSkills
    [ BrainF,
      Video,
      Web,
      Phatic,
      Math,
      Time,
      Recall,
      Debug
    ]

-- Parse a given user request and run the corresponding action
handleRequest :: String -> StateT Memory (InputT IO) ()
handleRequest str = do
  -- Parse and update state
  let parserAction = runParserT parseRequest "" str
  result <- mapStateT liftIO parserAction

  -- Allow IO actions to be interrupted with <Control-C>
  let interruptable = handleInterrupt (outputStrLn "\nInterrupted.") . withInterrupt
  let liftInterruptableIO action = lift $ interruptable $ liftIO action

  liftInterruptableIO $ case result of
    Left error -> handleErrorBundle error
    Right action -> action

-- The REPL's primary loop
loop :: StateT Memory (InputT IO) ()
loop = do
  request <- lift $ getInputLine prompt

  case request of
    Nothing -> pure () -- Stop REPL
    Just "" -> loop -- Forgive accidental enter presses
    Just str -> handleRequest str >> loop

-- REPL for the AI
-- Run each monad transformer layer to get a final IO action
runREPL :: IO ()
runREPL = runInputT defaultSettings (evalStateT loop Memory.initial)
