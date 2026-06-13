module LGPT.Skills.BrainF (parser, help) where

-- Implementation of BrainF, an esoteric turing complete programming language
-- https://esolangs.org/wiki/Brainfuck

import Control.Monad.State
import Data.Char (chr, ord)
import Data.Word (Word8)
import LGPT.Grammar
import LGPT.Helpers (printSkillHelp)
import LGPT.Memory qualified as Memory
import Text.Megaparsec hiding (Token)
import Text.Megaparsec.Char
import Text.Megaparsec.Char.Lexer qualified as L

help :: IO ()
help =
  printSkillHelp
    "BrainF"
    "Implementation of BrainF, an esoteric turing complete programming language."
    [("Run [EXPRESSION]", "Evaluate an expression")]
    [ "Run -[------->+<]>-.-[->+++++<]>++.+++++++..+++.[--->+<]>----.[--->+<]>-.",
      "Run --[----->+<]>---.--.--[--->+<]>-.>++++++++++.>+[>,.<]",
      "Run that"
    ]

-- Unsigned 8 bit cells with overflow and underflow
type Cell = Word8

newtype Tape
  = Tape
      ( [Cell], -- Cells to the left of the pointer (reverse order, makes cons easier)
        Cell, -- Cells under the pointer
        [Cell] -- Cells to the right of the pointer
      )

-- Inital state of the memory tape
-- Rightward infinite, with 0 as the default value, and with the pointer on the first cell
emptyTape :: Tape
emptyTape = Tape ([], 0, repeat 0)

type TapeIO = StateT Tape IO

-- A token in a BrainF expression
data Token
  = ShiftLeft
  | ShiftRight
  | Increment
  | Decrement
  | Input
  | Output
  | Nop
  | Loop ![Token]

instance Show Token where
  show ShiftLeft = "<"
  show ShiftRight = ">"
  show Increment = "+"
  show Decrement = "-"
  show Input = ","
  show Output = "."
  show Nop = ""
  show (Loop tokens) = "[" ++ concatMap show tokens ++ "]"

-- Run the action associated with each token
evaluateToken :: Token -> TapeIO ()

-- Move the pointer left
evaluateToken ShiftLeft = modify shiftPointerLeft
  where
    shiftPointerLeft tape@(Tape ([], _, _)) = tape
    shiftPointerLeft (Tape (l : ls, c, rs)) = Tape (ls, l, c : rs)

-- Move the pointer right
evaluateToken ShiftRight = modify shiftPointerRight
  where
    shiftPointerRight tape@(Tape (_, _, [])) = tape -- In case the tape is finite
    shiftPointerRight (Tape (ls, c, r : rs)) = Tape (c : ls, r, rs)

-- Increment the cell under the pointer
-- NOTE: Cannot use `succ` here since it can't overflow
evaluateToken Increment = modify incrementCell
  where
    incrementCell (Tape (ls, c, rs)) = Tape (ls, c + 1, rs)

-- Decrement the cell under the pointer
-- NOTE: Cannot use `pred` here since it can't underflow
evaluateToken Decrement = modify decrementCell
  where
    decrementCell (Tape (ls, c, rs)) = Tape (ls, c - 1, rs)

-- Input a character from the user and store it in the cell under the pointer
evaluateToken Input = do
  c <- liftIO getChar
  modify (\(Tape (ls, _, rs)) -> Tape (ls, fromIntegral (ord c), rs))

-- Output the character in the cell into stdout
evaluateToken Output = do
  Tape (_, c, _) <- get
  liftIO $ putChar (chr (fromIntegral c))

-- Do nothing
evaluateToken Nop = pure ()

-- Repeatedly evaluate an expression until a 0 is under the pointer
evaluateToken (Loop tokens) = do
  Tape (_, c, _) <- get

  when (c /= 0) $ do
    evaluateExpression tokens
    evaluateToken (Loop tokens)

-- Evaluate an expression as a sequence of tokens
evaluateExpression :: [Token] -> TapeIO ()
evaluateExpression = mapM_ evaluateToken

-- Parse a full BrainF expression
parseExpression :: Parser [Token]
parseExpression =
  many $
    choice
      [ char '<' >> pure ShiftLeft,
        char '>' >> pure ShiftRight,
        char '+' >> pure Increment,
        char '-' >> pure Decrement,
        char ',' >> pure Input,
        char '.' >> pure Output,
        Loop <$> between (char '[') (char ']') parseExpression,
        notFollowedBy (char ']') >> anySingle >> pure Nop -- Invalid characters
      ]

-- Parse "that" and change the input stream to be the previous evaluation
parseThat :: Parser ()
parseThat = do
  expression <- that
  requestEnd

  setInput expression

-- Parse an expression, store it and then evaluate it
-- Avoids using some utilities from `Grammar` to avoid ambiguity with punctuation
parser :: Parser (IO ())
parser = do
  hspace
  politenessMarker
  L.symbol' hspace "run"
  optional parseThat
  expression <- parseExpression

  Memory.remember "that" (concatMap show expression)

  pure $ evalStateT (evaluateExpression expression) emptyTape
