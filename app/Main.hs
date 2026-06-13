module Main where

-- Entry point to the program, sets up and starts the REPL
-- Check out some of the demos in the demos/ folder!

-- NOTE: I've modified package.yaml, stack.yaml, and test/Spec.hs

import LGPT.Helpers (runStart)
import LGPT.TUI qualified as TUI

main :: IO ()
main = do
  -- Pre-initialisation to set up the terminal
  runStart

  -- Actually run the loop!
  TUI.runREPL
