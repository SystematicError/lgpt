#!/usr/bin/env bash

# Plays the Bad Apple video

# Personally tested on the Ghostty terminal with JetBrainsMono as the font - renders as intended

demo() {
    echo "clear"
    echo "echo \"Bad Apple - Played entirely within the terminal using unicode characters!\""
    echo "echo \"Mileage may vary depending on your font and terminal\""
    echo "echo \"Done using the Video skill\""
    echo "echo \"Press <Control-C> to stop the video\""
    echo "play bad apple"
    echo "echo \"Here's the video again, but at 5x speed\""
    echo "play bad apple at 5x speed"
}

demo | stack run
