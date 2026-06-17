# What Is LGPT?

LGPT or λGPT is a versatile multipurpose chatbot utilising the [Megaparsec](https://hackage.haskell.org/package/megaparsec) library's monadic parsing capabilities.

I have produced a [report](https://github.com/SystematicError/lgpt/blob/main/report.pdf) briefly describing the codebase structure, the AI's feature set, and some internal architectural decisions. I have also written a small [blog post](https://pranavmanoj.net/blog/megaparsec-stateful) showing how to write similar parsers with "memory" using monad transformers.

This project was submitted as part of the coursework required by my university's [CS141](https://warwick.ac.uk/fac/sci/dcs/teaching/modules/cs141/) module, and was awarded a grade of 100% (High First Class).

![Demo image](https://github.com/user-attachments/assets/5885476f-4c96-44b9-bd98-493a51a76bda)

# Skills

LGPT includes various features through skills. Each skill implements a set of specific commands, and some skills integrate with each other. You can learn more about a skill by using the `Help with [SKILL]` command.

| Name   | Description                                                                                                       |
| ------ | ----------------------------------------------------------------------------------------------------------------- |
| BrainF | Implementation of [BrainF](https://esolangs.org/wiki/Brainfuck), an esoteric turing complete programming language |
| Web    | Make HTTP(S) requests and extract JSON data                                                                       |
| Video  | Replays video files as unicode characters, completely within the terminal                                         |
| Recall | Interact directly with the AI's memory                                                                            |
| Math   | Evaluates left associative mathematical expressions in numeric and longhand form                                  |
| Time   | Perform date and day related calculations                                                                         |
| Phatic | Reply to [phatic requests](https://en.wikipedia.org/wiki/Phatic_expression)                                       |
| Debug  | Debug commands to interact directly with the terminal and the AI                                                  |

# Usage

| Command                       | Description                                  |
| ----------------------------- | -------------------------------------------- |
| `stack run`                   | Start an interactive REPL with the chatbot   |
| `echo "command" \| stack run` | Evaluate a given `command` using the chatbot |
| `stack test`                  | Test suite                                   |

Additionally, some shell scripts have been included under the `demos/` folder which execute a set of commands to demonstrate some features.
