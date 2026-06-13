module LGPT.Numbers where

-- Parsing and displaying numbers in numeric and longhand form

import LGPT.Grammar
import Text.Megaparsec
import Text.Megaparsec.Char
import Text.Megaparsec.Char.Lexer qualified as L

-- Parse unsigned integers in numeric form
integer' :: (Integral a) => Parser a
integer' = lexeme L.decimal

-- Parse unsigned integers in numeric and longhand form
integer :: (Integral a) => Parser a
integer = tryChoice [integer', parseLonghand]

-- Parse unsigned fractional numbers in numeric form
fractional' :: (RealFloat a) => Parser a
fractional' = tryChoice [lexeme L.float, fromIntegral <$> integer']

-- Parse unsigned fractional numbers in numeric and longhandform
fractional :: (RealFloat a) => Parser a
fractional = tryChoice [fractional', fromIntegral <$> parseLonghand]

-- Print an integer in longhand form
printLonghand :: Int -> String
printLonghand n
  | n > 1000000 = "an unfathomably large number"
  | n == 1000000 = "one million"
  | n == 0 = "zero"
  | n >= 1000 =
      let thouStr = printLonghand (n `div` 1000) ++ " thousand"
          and = if n `mod` 1000 >= 100 then " " else " and "
          hundStr = printLonghand (n `mod` 1000)
       in if n `mod` 1000 == 0
            then thouStr
            else thouStr ++ and ++ hundStr
  | n >= 100 =
      let hundStr = printLonghand (n `div` 100) ++ " hundred"
          tensStr = printLonghand (n `mod` 100)
       in if n `mod` 100 == 0
            then hundStr
            else hundStr ++ " and " ++ tensStr
  | n >= 20 =
      let tensStr = tens !! ((n `div` 10) - 2)
          hyphen = if n `mod` 10 /= 0 then "-" else ""
          unitStr = ("" : oneToNine) !! (n `mod` 10)
       in tensStr ++ hyphen ++ unitStr
  | n > 0 = ("" : oneToNine ++ tenToTwenty) !! n
  | otherwise = "a negative number"

-- Parse an integer in longhand form
-- Refactored to use the more flexible lexemes provided by `Grammar.hs`
-- The "thousand bug" has also been fixed
parseLonghand :: (Integral a) => Parser a
parseLonghand =
  tryChoice
    [ phrase "one million" >> pure 1000000,
      parseSubMillion,
      parseSubThousand,
      parseSubHundred,
      word "zero" >> pure 0
    ]
  where
    parseSubMillion :: (Integral a) => Parser a
    parseSubMillion = do
      thousands <- tryChoice [parseSubThousand, parseSubHundred]
      word "thousand"
      rest <-
        tryChoice
          [ word "and " >> parseSubHundred,
            parseSubThousand,
            pure 0
          ]
      pure $ thousands * 1000 + rest

    parseSubThousand :: (Integral a) => Parser a
    parseSubThousand = do
      hundreds <- parseUnit
      word "hundred"
      rest <- (word "and" >> parseSubHundred) <|> pure 0
      pure $ hundreds * 100 + rest

    parseSubHundred :: (Integral a) => Parser a
    parseSubHundred =
      tryChoice
        [ do
            tens <- choice $ zipWith (\s n -> word s >> pure n) tens [20, 30 .. 90]
            rest <- parseUnit <|> pure 0
            pure $ tens + rest,
          parseTenToTwenty,
          parseUnit
        ]

    parseTenToTwenty :: (Integral a) => Parser a
    parseTenToTwenty = choice $ zipWith (\s n -> word s >> pure n) tenToTwenty [10 .. 19]

    parseUnit :: (Integral a) => Parser a
    parseUnit = choice $ zipWith (\s n -> word s >> pure n) oneToNine [1 .. 9]

-- Helpers used for both parsing and printing

oneToNine :: [String]
oneToNine =
  ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]

tenToTwenty :: [String]
tenToTwenty =
  [ "ten",
    "eleven",
    "twelve",
    "thirteen",
    "fourteen",
    "fifteen",
    "sixteen",
    "seventeen",
    "eighteen",
    "nineteen"
  ]

tens :: [String]
tens =
  [ "twenty",
    "thirty",
    "forty",
    "fifty",
    "sixty",
    "seventy",
    "eighty",
    "ninety"
  ]
