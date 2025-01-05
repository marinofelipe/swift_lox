//
//  Environment.swift
//  swift-lox
//
//  Created by Marino Felipe on 04.01.25.
//

final class Environment {
  typealias VariableName = String

  private var values: [VariableName: LiteralValue] = [:]

  func get(_ token: Token) throws -> LiteralValue {
    guard let value = values[token.lexeme] else {
      // For lox, the error is runtime instead of compile-time, because
      // otherwise it's tricky to deal with recursive functions and because Lox's program
      // is a sequence of imperative statements and do a single pass over the source code.
      throw RuntimeError(
        token: token,
        message: "Undefined variable '\(token.lexeme)'."
      )
    }

    return value
  }

  func define(_ name: VariableName, _ value: LiteralValue) {
    // it doesn't check for the existence of the key,
    // which means the language allows redefining a variable statement
    values[name] = value
  }
}

//“My rule about variables and scoping is, “When in doubt, do what Scheme does”.
//The Scheme folks have probably spent more time thinking about variable scope
//than we ever will—one of the main goals of Scheme was to introduce lexical
//scoping to the world—so it’s hard to go wrong if you follow in their
//footsteps.
//Scheme allows redefining variables at the top level.”
//
//Excerpt From
//Crafting Interpreters
//Robert Nystrom
//https://books.apple.com/de/book/crafting-interpreters/id1578795812?l=en-GB
//This material may be protected by copyright.

func scope() {
  let b = 3
  func innerScope() {
    let a = b + 1
    print(a)
  }
}
