#!/usr/bin/env bash

# Fetches some BrainF code from the internet and runs in on the fly

# Here are some more programs (unfortunately these can't be put into a demo script since they're interactive)
#
# Ghost Minigame - https://www.brainfuck.org/ghost.b
# Conway's Game of Life (cellular automaton) - https://www.brainfuck.org/life.b
# 15 puzzle - https://raw.githubusercontent.com/arkark/15puzzle-brainfuck/refs/heads/master/src/15puzzle.bf
#
# I recommend that you run `set no buffering` if you're running the 15 puzzle program

demo() {
    echo "get \"https://www.brainfuck.org/sierpinski.b\""
    echo "clear"
    echo "echo \"A Serpinski fractal rendered programatically\""
    echo "echo \"The code for the program is downloaded from the web and evaluated on the fly!\""
    echo "echo \"The BrainF language is turing complete, and capable of much more!\""
    echo "echo \"---> Check the demo file for more programs <---\""
    echo "echo \"Done using the Web and BrainF skills\""
    echo "run that"
}

demo | stack run
