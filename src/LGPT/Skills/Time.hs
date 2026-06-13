module LGPT.Skills.Time (parser, help) where

-- Perform date and day related calculations

import Data.Time qualified as Time
import LGPT.Grammar
import LGPT.Helpers (printSkillHelp)
import LGPT.Numbers
import Text.Megaparsec

help :: IO ()
help =
  printSkillHelp
    "Time"
    "Perform date and day related calculations."
    [ ("What day is it", "Find what day is it today"),
      ("What day is it [PERIOD]", "Find what day it will be in the future by a given period"),
      ("What day was it [PERIOD]", "Find what day it was in the past by a given period"),
      ("How long ago was [DATE]", "Find how many days it has been since a past date")
    ]
    [ "What day is it",
      "What day is it tomorrow",
      "What day is it in 5 weeks",
      "What day was it day before yesterday",
      "What day was it twenty years ago",
      "How long ago was 2007-07-01"
    ]

-- Polymorphic type so that some useful typeclasses can be derived
data TimePeriod' a
  = Days !a
  | Weeks !a
  | Months !a
  | Years !a
  deriving (Functor, Foldable)

-- Measures how far a day is from today
-- NOTE: Using `Integer` instead of `Int` since that's what the time library uses
type TimePeriod = TimePeriod' Integer

-- Find what day it will be after a given time period
periodToDay :: TimePeriod -> IO String
periodToDay period = do
  today <- Time.utctDay <$> Time.getCurrentTime

  let day = case period of
        Days n -> Time.addDays n today
        Weeks n -> Time.addDays (7 * n) today
        Months n -> Time.addGregorianMonthsClip n today
        Years n -> Time.addGregorianYearsClip n today

  pure $ Time.formatTime Time.defaultTimeLocale "%A" day

-- Print the day after a period, formatted depending on the direction of the period
printDayAfter :: TimePeriod -> IO String
-- Edge case, formatted how the test case expects it
printDayAfter period@(Days 1) = do
  day <- periodToDay period
  pure $ "Tomorrow is " ++ day ++ "."
printDayAfter period = do
  day <- periodToDay period

  -- "Unlift" the day offset from the period data type
  let n = foldr1 const period

  pure $ case n `compare` 0 of
    EQ -> "Today is " ++ day ++ "."
    GT -> "It will be " ++ day ++ "."
    LT -> "It was " ++ day ++ "."

-- Period given by a number value
parseNumericPeriod :: Parser TimePeriod
parseNumericPeriod = do
  n <-
    choice
      [ integer,
        word "a" >> pure 1
      ]

  period <-
    choice
      [ word "day" >> pure (Days n),
        word "week" >> pure (Weeks n),
        word "month" >> pure (Months n),
        word "year" >> pure (Years n)
      ]

  optional $ word "s"

  pure period

-- Period given using a special alias

parseFutureSpecialPeriod :: Parser TimePeriod
parseFutureSpecialPeriod =
  choice
    [ word "today" >> pure (Days 0),
      word "tomorrow" >> pure (Days 1),
      phrase "day after tomorrow" >> pure (Days 2),
      pure (Days 0)
    ]

parsePastSpecialPeriod :: Parser TimePeriod
parsePastSpecialPeriod =
  choice
    [ word "today" >> pure (Days 0),
      word "yesterday" >> pure (Days (-1)),
      phrase "day before yesterday" >> pure (Days (-2)),
      pure (Days 0)
    ]

-- Periods into the future
parseFuturePeriod :: Parser TimePeriod
parseFuturePeriod = do
  phrase "is it"
  choice
    [ word "in" >> parseNumericPeriod,
      parseFutureSpecialPeriod
    ]

-- Periods into the past
parsePastPeriod :: Parser TimePeriod
parsePastPeriod = do
  phrase "was it"
  choice
    [ fmap negate <$> parseNumericPeriod <* word "ago",
      parsePastSpecialPeriod
    ]

-- Parses and prints the day before or after a time period
parseRelativeDay :: Parser (IO ())
parseRelativeDay = do
  phrase "what day"
  period <- parseFuturePeriod <|> parsePastPeriod

  pure $ printDayAfter period >>= putStrLn

-- How many days into the past is a date from today
differenceFromToday :: Time.Day -> IO Integer
differenceFromToday date = do
  today <- Time.utctDay <$> Time.getCurrentTime
  pure $ Time.diffDays today date

-- Parse a YYYY-MM-DD date, fails if an invalid date is provided
parseGregorian :: Parser Time.Day
parseGregorian = do
  year <- integer'
  month <- integer'
  day <- integer'

  case Time.fromGregorianValid year month day of
    Nothing -> fail "Sorry, that date is invalid."
    Just date -> pure date

-- Parses and prints how many days ago a date was
parseDateDifference :: Parser (IO ())
parseDateDifference = do
  phrase "how long ago was"
  date <- parseGregorian

  pure $ do
    difference <- differenceFromToday date
    putStrLn $ show date ++ " was " ++ show difference ++ " days ago."

parser :: Parser (IO ())
parser = request $ parseRelativeDay <|> parseDateDifference
