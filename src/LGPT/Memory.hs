{-# LANGUAGE OverloadedLists #-}

module LGPT.Memory where

-- Data type representing the AI's internal memory, and provides state actions to interact with it
-- Intended to be imported qualified

import Control.Monad.State
import Data.Char (toLower)
import Data.Map (Map)
import Data.Map qualified as Map

newtype Memory = Memory (Map String String)
  deriving (Show)

-- Normalise key strings before accessing them
-- This can be extended, but for now this suffices, the parser handles stuff like punctuation
normalise :: String -> String
normalise = map toLower

-- Initial memory state
initial :: Memory
initial =
  Memory
    [ ("lgpt", "a decently powerful AI"),
      ("cs141", "a functional programming module"),
      ("haskell", "a general-purpose, statically typed, purely functional programming language with type inference and lazy evaluation"),
      ("the meaning of life the universe and everything", "42")
    ]

-- Record an entry
remember :: (MonadState Memory m) => String -> String -> m ()
remember key value = modify remember'
  where
    remember' (Memory memory) = Memory $ Map.insert (normalise key) value memory

-- Delete an entry
forget :: (MonadState Memory m) => String -> m ()
forget key = modify forget'
  where
    forget' (Memory memory) = Memory $ Map.delete (normalise key) memory

-- Lookup an entry
recall :: (MonadState Memory m) => String -> m (Maybe String)
recall key = do
  (Memory memory) <- get
  pure $ Map.lookup (normalise key) memory
