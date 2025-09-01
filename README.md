# Swift Lox

A Swift port of Robert Nystrom's Lox Tree-Walk Interpreter from the book [Crafting Interpreters](https://craftinginterpreters.com/contents.html).


### Features and design choices

Implemented based on the challenges that the book proposes.

- [x] C-style `/* ... */` block comments
- [x] Ternary
- [x] [Comma Operator](https://en.wikipedia.org/wiki/Comma_operator)
- [x] Error on binary operators without a left-hand operand (_in Chapter 6 Challenges_)
- [ ] String comparison. Also consider comparison for other types
- [x] String and string covertible concatenation: `"1" + "more"` yields `"1more"`
- [x] Runtime error on number divided by zero
