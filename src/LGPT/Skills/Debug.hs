module LGPT.Skills.Debug (parser, help) where

-- Debug commands to interact directly with the terminal and the AI

import Control.Monad.State
import LGPT.Grammar
import LGPT.Helpers (printSkillHelp)
import System.Console.ANSI
import System.IO
import Text.Megaparsec

help :: IO ()
help =
  printSkillHelp
    "Debug"
    "Debug commands to interact directly with the terminal and the AI."
    [ ("Clear", "Clear the screen"),
      ("Echo [STRING]", "Prints the given string back to the terminal"),
      ("Set no buffering", "Disable buffering for the terminal"),
      ("Set line buffering", "Enable line buffering for the terminal"),
      ("Dump memory", "Print everything in the AI's memory")
    ]
    []

parseClear :: Parser (IO ())
parseClear = do
  word "clear"
  pure $ clearScreen >> setCursorPosition 0 0

parseEcho :: Parser (IO ())
parseEcho = do
  word "echo"
  str <- entity requestEnd
  pure $ putStrLn str

parseNoBuffering :: Parser (IO ())
parseNoBuffering = do
  phrase "set no buffering"
  pure $ hSetBuffering stdin NoBuffering

parseLineBuffering :: Parser (IO ())
parseLineBuffering = do
  phrase "set line buffering"
  pure $ hSetBuffering stdin LineBuffering

parseDumpMemory :: Parser (IO ())
parseDumpMemory = do
  phrase "dump memory"
  gets print

parser :: Parser (IO ())
parser =
  request $
    choice
      [ parseClear,
        parseEcho,
        parseNoBuffering,
        parseLineBuffering,
        parseDumpMemory
      ]
