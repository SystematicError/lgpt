module LGPT.Helpers where

-- Helper functions for setting up and printing to the terminal

import Control.Monad (unless, when)
import System.Console.ANSI
import System.IO

-- The prompt to show the user when asking for input.
prompt :: String
prompt = "λ> "

-- Set up the interactive terminal session.
runStart :: IO ()
runStart = do
  isTTY <- hIsTerminalDevice stdin

  -- Only do the interactive setup when running interactively.
  when isTTY $ do
    -- Clear away the stack build details.
    clearScreen

    -- We set this so the prompt will always print out right away.
    hSetBuffering stdout NoBuffering

    -- Change text to magenta
    setSGR [SetColor Foreground Vivid Magenta]

    -- Print a nice picture
    mapM_
      putStrLn
      [ "    ___     _____ _____ _______  ",
        "    \\  \\   / ____|  __ \\__   __| ",
        "     \\  \\ | |  __| |__) | | |    ",
        "      >  \\| | |_ |  ___/  | |    ",
        "     / /\\ | |__| | |      | |    ",
        "    /_/  \\_\\_____|_|      |_|    ",
        "The Lightly Generalised Parsing Task",
        ""
      ]

    -- Change text to grey
    setSGR [SetColor Foreground Dull White]

    -- Print footer
    mapM_
      putStrLn
      [ "Hint: This REPL is interactive!",
        "Note: Type \"Help\" to learn more...",
        "Note: Type \"Help with [SKILL]\" to learn more about a skill...",
        ""
      ]

    -- Unset the colour
    setSGR [Reset]

printSkillHelp :: String -> String -> [(String, String)] -> [String] -> IO ()
printSkillHelp title description usage examples = do
  -- Print the skill title

  setSGR
    [ SetColor Background Vivid Magenta,
      SetColor Foreground Dull Black,
      SetConsoleIntensity BoldIntensity
    ]

  -- Sending `Reset` before newline to prevent the background color from spilling
  putStr $ " ◂ " ++ title ++ " ▸ "
  setSGR [Reset]
  putStrLn ""

  -- Print lines with indentation
  let indent = "  "
  let putStrLn' str = putStrLn $ indent ++ str
  let putStrLn'' str = putStrLn $ indent ++ indent ++ str

  -- Print the skill description
  putStrLn' $ description ++ "\n"

  -- Print an underlined section title
  let printTitle title = do
        setSGR [SetConsoleIntensity BoldIntensity]

        putStrLn' title

        setSGR [SetColor Foreground Dull White]

        putStrLn' $ replicate (length title) '─'

        setSGR [Reset]

  -- Print a command usage section
  let printUsage (command, commandDescription) = do
        putStrLn'' command

        setSGR [SetColor Foreground Dull White]

        putStrLn'' $ commandDescription ++ "\n"

        setSGR [Reset]

  -- Print command usage
  unless (null usage) $ do
      printTitle "Usage"
      mapM_ printUsage usage

  -- Print command usage
  unless (null examples) $ do
      printTitle "Examples"
      mapM_ putStrLn'' examples
      putStrLn ""
