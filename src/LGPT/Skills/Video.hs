{-# LANGUAGE TemplateHaskell #-}

module LGPT.Skills.Video (parser, help) where

-- Replays video files as unicode characters, completely within the terminal

{-
Package Justification
---------------------
file-embed - Embed video files at compiletime, removes the hassle of runtime filesystem operations
-}

import Control.Concurrent (threadDelay)
import Data.ByteString (ByteString)
import Data.ByteString qualified as B
import Data.FileEmbed (embedFile)
import Data.Maybe (fromMaybe)
import LGPT.Grammar
import LGPT.Helpers (printSkillHelp)
import LGPT.Numbers
import Text.Megaparsec

help :: IO ()
help =
  printSkillHelp
    "Video"
    "Replays video files as unicode characters, completely within the terminal."
    [ ("Play [VIDEO]", "Play a video"),
      ("Play [VIDEO] at [MULTIPLIER] speed", "Play a video at given speed")
    ]
    [ "Play Bad Apple",
      "Play Bad Apple at 0.5x speed",
      "Play This is America at five times speed"
    ]

-- Videos are represented as a stream of frame characters and the original frame rate
-- Pre rendered using the `render_video.sh` script
-- Make sure that your terminal supports the symbol set and color options
newtype Video = Video (ByteString, Float)

-- Delimiter between each frame in the video file
-- This should always be the escape code \x1b[u when using the render script
frameEndMarker :: ByteString
frameEndMarker = B.pack [0x1b, 0x5b, 0x75]

-- Full video from https://www.youtube.com/watch?v=FtutLA63Cp8
badApple :: Video
badApple = Video ($(embedFile "assets/BadApple_40x15_noneBit_narrowSym_24Fps"), 24)

-- Video excerpt from https://www.youtube.com/watch?v=VYOjWnS4cMY
thisIsAmerica :: Video
thisIsAmerica = Video ($(embedFile "assets/ThisIsAmerica_72x20_fullBit_allSym_24Fps"), 24)

-- Output the video frames into stdout
playVideo :: Video -> IO ()
playVideo (Video (frameStream, frameRate))
  -- Stop at the end of the stream
  | B.null frameStream = pure ()

  -- Wait for a bit at the end of a frame
  | frameEndMarker `B.isPrefixOf` frameStream = do
      threadDelay (round (1000000 / frameRate))
      B.putStr frameEndMarker
      playVideo (Video (B.drop (B.length frameEndMarker) frameStream, frameRate))

  -- Print frame bytes
  | otherwise = do
      let (frame, rest) = B.breakSubstring frameEndMarker frameStream
      B.putStr frame
      playVideo (Video (rest, frameRate))

-- Modify the framerate of a video with a multiplier
modifyFrameRate :: Video -> Float -> Video
modifyFrameRate (Video (frameStream, frameRate)) multiplier = Video (frameStream, frameRate * multiplier)

-- Video name
parseVideo :: Parser Video
parseVideo =
  choice
    [ phrase "bad apple" >> pure badApple,
      phrase "this is america" >> pure thisIsAmerica
    ]

-- Video speed multiplier
parseSpeed :: Parser Float
parseSpeed = do
  word "at"

  speed <- fractional

  optional $ wordChoice ["times", "x"]
  optional $ word "speed"

  pure speed

parser :: Parser (IO ())
parser = request $ do
  word "play"

  video <- parseVideo
  multiplier <- fromMaybe 1 <$> optional parseSpeed

  pure $ playVideo $ modifyFrameRate video multiplier
