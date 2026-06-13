module LGPT.Skills (mergeSkills, Skill (..)) where

-- Aggregates skills and generates a full parser for them, along with a help command

import LGPT.Grammar
import LGPT.Skills.BrainF qualified as BrainF
import LGPT.Skills.Debug qualified as Debug
import LGPT.Skills.Math qualified as Math
import LGPT.Skills.Phatic qualified as Phatic
import LGPT.Skills.Recall qualified as Recall
import LGPT.Skills.Time qualified as Time
import LGPT.Skills.Video qualified as Video
import LGPT.Skills.Web qualified as Web
import Text.Megaparsec

-- To register a new skill, add a constructor to `Skill` and implement `getInfo` for it

data Skill
  = BrainF
  | Debug
  | Math
  | Phatic
  | Recall
  | Time
  | Video
  | Web
  deriving (Show)

data SkillInfo = SkillInfo
  { getParser :: !(Parser (IO ())), -- Parser for the skill
    getHelp :: !(IO ()) -- Help action for a skill
  }

-- Get information associated with a skill
getInfo :: Skill -> SkillInfo
getInfo BrainF = SkillInfo BrainF.parser BrainF.help
getInfo Debug = SkillInfo Debug.parser Debug.help
getInfo Math = SkillInfo Math.parser Math.help
getInfo Phatic = SkillInfo Phatic.parser Phatic.help
getInfo Recall = SkillInfo Recall.parser Recall.help
getInfo Time = SkillInfo Time.parser Time.help
getInfo Video = SkillInfo Video.parser Video.help
getInfo Web = SkillInfo Web.parser Web.help

-- Generate a help parser from a list of skills
parseHelp :: [Skill] -> Parser (IO ())
parseHelp skills = request $ do
  word "help"
  optional $ word "me"

  maybeSkillHelp <- optional $ do
    word "with"

    -- Parse the name of a specific skill and return its help text
    tryChoice $ map (\skill -> word (show skill) >> pure ((getHelp . getInfo) skill)) skills

  pure $ case maybeSkillHelp of
    -- If no specific skill was specified, give the help text for every registered skill
    Nothing -> mapM_ (getHelp . getInfo) skills
    Just helpAction -> helpAction

-- Merge all the given skills and their help parser
-- Order matters, parsers are prioritised in the given order
mergeSkills :: [Skill] -> Parser (IO ())
mergeSkills skills = tryChoice $ parseHelp skills : map (getParser . getInfo) skills
