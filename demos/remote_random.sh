#!/usr/bin/env bash

# Fetches a random number from the internet and performs some arithmetic on it

demo() {
    echo "get \"https://www.randomnumberapi.com/api/v1.0/random?min=100&max=10000\" selecting > 0"
    echo "clear"
    echo "echo \"Done using the Web and Math skills\""
    echo "echo \"Here's a random number:\""
    echo "what is that"
    echo "echo \"Now here's the next few consecutive numbers:\""
    echo "what is that plus one"
    echo "what is that plus one"
    echo "what is that plus one"
    echo "what is that plus one"
}

demo | stack run
