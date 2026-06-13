module LGPT.Skills.Math (parser, help) where

-- Evaluates left associative mathematical expressions in numeric and longhand form

import Data.Function ((&))
import Data.List (foldl')
import LGPT.Grammar
import LGPT.Helpers (printSkillHelp)
import LGPT.Memory qualified as Memory
import LGPT.Numbers
import Text.Megaparsec
import Text.Read (readMaybe)

help :: IO ()
help =
  printSkillHelp
    "Math"
    "Evaluates left associative mathematical expressions in numeric and longhand form."
    [("What is [EXPRESSION]", "Calculates a given expression")]
    [ "What is one plus one",
      "What is that times 62",
      "What is that minus 2 times thirty plus one",
      "What is that minus that",
      "What is that"
    ]

data Expression
  = Number !Int
  | Add !Expression !Expression
  | Subtract !Expression !Expression
  | Multiply !Expression !Expression

evaluateExpression :: Expression -> Int
evaluateExpression (Number n) = n
evaluateExpression (Add x y) = evaluateExpression x + evaluateExpression y
evaluateExpression (Subtract x y) = evaluateExpression x - evaluateExpression y
evaluateExpression (Multiply x y) = evaluateExpression x * evaluateExpression y

parseNumber :: Parser Expression
parseNumber = choice [parseThat, Number <$> integer]
  where
    -- Result of the previous evaluation
    parseThat :: Parser Expression
    parseThat = do
      result <- that

      -- Try reading as an integer, throw a failure if that isn't possible
      case readMaybe @Int result of
        Nothing -> fail "Previous evaluation isn't a valid integer."
        Just num -> pure $ Number num

-- Operations are operator-term pairs that transform other expressions
parseOperation :: Parser (Expression -> Expression)
parseOperation = do
  operator <-
    choice
      [ word "plus" >> pure Add,
        word "minus" >> pure Subtract,
        word "times" >> pure Multiply
      ]

  right <- parseNumber

  pure (`operator` right)

parseExpression :: Parser Expression
parseExpression = do
  base <- parseNumber
  operations <- many parseOperation

  -- Apply the operators one by one onto the base term to get the final result
  pure $ foldl' (&) base operations

parser :: Parser (IO ())
parser = request $ do
  phrase "what is"
  expression <- parseExpression

  let result = evaluateExpression expression
  Memory.remember "that" (show result)

  pure $ putStrLn $ "The answer is " ++ printLonghand result ++ "."
