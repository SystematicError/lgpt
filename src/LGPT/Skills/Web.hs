{-# LANGUAGE ImpredicativeTypes #-}

module LGPT.Skills.Web (parser, help) where

-- Make HTTP(S) requests and extract JSON data

{-
Package Justification
---------------------
aeson - Industry standard JSON parsing library

aeson-pretty - Format JSON nicely to display to the user

lens, lens-aeson - Useful to select and extract JSON data through traversals

wreq
    - Reasonably modern, efficient, and feature rich library
    - Integrates well with aeson
    - Lens centric API fits well with lens and lens-aeson
    - Easy to use API, especially compared to packages like req
    - Overall, there seem to be a lot of HTTP packages, wreq seems to be the best fit here
-}

import Control.Exception qualified as E
import Control.Lens
import Control.Lens.Reified (ReifiedTraversal')
import Control.Monad (void)
import Control.Monad.IO.Class (liftIO)
import Data.Aeson (Value (..), decode)
import Data.Aeson.Encode.Pretty (encodePretty)
import Data.Aeson.Key qualified as K
import Data.Aeson.Lens (key, nth)
import Data.ByteString.Lazy (ByteString)
import Data.ByteString.Lazy.Char8 qualified as B
import Data.List (foldl')
import Data.Maybe (fromMaybe)
import Data.Text qualified as T
import LGPT.Grammar
import LGPT.Helpers (printSkillHelp)
import LGPT.Memory qualified as Memory
import LGPT.Numbers
import Network.HTTP.Client (HttpException)
import Network.Wreq
import Text.Megaparsec

help :: IO ()
help =
  printSkillHelp
    "Web"
    "Make HTTP(S) requests and extract JSON data"
    [ ("Get \"[URL]\"", "Make a GET request to a URL"),
      ("Get \"[URL]\" selecting [SELECTION]", "Make a GET request to a URL and select the JSON response"),
      ("Post \"[URL]\"", "Make a POST request to a URL"),
      ("Post \"[URL]\" with body \"[BODY]\"", "Make a POST request to a URL with a BODY"),
      ("Post \"[URL]\" selecting [SELECTION]", "Make a POST request to a URL and select the JSON response")
    ]
    [ "Get \"https://example.com\"",
      "Get \"https://httpbin.org/json\"",
      "Get \"https://httpbin.org/json\" selecting > slideshow > slides > 0 > title",
      "Get \"https://en.wikipedia.org/w/rest.php/v1/search/page?q=haskell\" selecting > pages > 0 > description",
      "Post \"https://httpbin.org/post\" with body \"Hello from LGPT!\" selecting > data",
      "Tell me about that"
    ]

-- A selection is essentially a JSON traversal using lenses
--
-- NOTE: Mixing `Traversal'` with `Parser` is a headache, GHC can't seem to infer the types properly
-- `ReifiedTraversal'` is a wrapper around `Traversal`, hiding away the underlying polymorphic type
-- The ImpredicativeTypes extension (as suggested by GHC) also helps with the types here
type Selection = ReifiedTraversal' Value Value

parseSelection :: Parser Selection
parseSelection = do
  word "selecting"

  selections <- some $ do
    word ">"
    choice
      [ Traversal . nth <$> integer',
        Traversal . key . K.fromString <$> entity (lookAhead (void $ word ">") <|> requestEnd)
      ]

  -- Merge all the selections into one
  pure $ Traversal $ foldl' (\xs x -> xs . runTraversal x) id selections

-- Perform a request, and return either an error message, or a selected and formatted response
getResponse :: IO (Response ByteString) -> Selection -> IO (Either String String)
getResponse = makeRequest
  where
    -- First, make the request and try getting its response
    makeRequest requestAction selection = do
      eitherResponse <- E.try @HttpException $ requestAction

      pure $ case eitherResponse of
        Left _ -> Left "Could not make a request to that URL."
        Right response -> getBody response selection

    -- If the request is successful, get the body of the response
    getBody response selection = case decode @Value body of
      -- Plain text responses are returned as is
      Nothing -> Right $ show body
      -- JSON responses are selected and formatted
      Just json -> selectJSON json selection
      where
        body = response ^. responseBody

    -- If the body is valid JSON, try selecting and formatting it
    selectJSON json selection = case preview (runTraversal selection) json of
      -- Format the selected JSON
      Just (String str) -> Right $ T.unpack str
      Just selected -> Right $ B.unpack $ encodePretty selected
      -- If selection fails
      Nothing -> Left "The selection doesn't match with the JSON response."

-- Parse a GET request and return an error message or its response
parseGet :: Parser (IO (Either String String))
parseGet = do
  word "get"

  url <- quoted
  selection <- fromMaybe (Traversal id) <$> optional parseSelection

  pure $ getResponse (get url) selection

-- Parse a POST request and return an error message or its response
parsePost :: Parser (IO (Either String String))
parsePost = do
  word "post"

  url <- quoted
  body <- B.pack . fromMaybe "" <$> optional (phrase "with body" >> quoted)
  selection <- fromMaybe (Traversal id) <$> optional parseSelection

  pure $ getResponse (post url body) selection

parser :: Parser (IO ())
parser = request $ do
  -- Parse and run the IO action to get a response
  eitherResponse <- parseGet <|> parsePost >>= liftIO

  -- If there is a response, store it and then print it, otherwise fail
  case eitherResponse of
    Left error -> fail error
    Right response -> do
      Memory.remember "that" response
      pure $ putStrLn response
