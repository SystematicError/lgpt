#!/usr/bin/env bash

# Queries wikipedia

demo() {
    echo "clear"
    echo "echo \"Querying Wikipedia's API for information on Neovim \""
    echo "echo \"Done using the Web skill\""
    echo "get \"https://en.wikipedia.org/w/api.php?format=json&action=query&prop=extracts&exintro&explaintext&redirects=1&titles=Neovim\" selecting > query > pages > \"49380718\" > extract"
}

demo | stack run
