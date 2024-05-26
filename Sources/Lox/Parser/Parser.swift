//
//  Parser.swift
//
//
//  Created by Marino Felipe on 12.05.24.
//

// precedence lowest to highest

//“The fact that the parser looks ahead at upcoming tokens to decide how to parse
//puts recursive descent into the category of predictive parsers.”

//“A parser really has two jobs:
//Given a valid sequence of tokens, produce a corresponding syntax tree.
//Given an invalid sequence of tokens, detect any errors and tell the
//user about their mistakes.”

//“Detect and report the error. If it doesn’t detect the error and passes the resulting malformed syntax tree on
//to the interpreter, all manner of horrors may be summoned.
//
//Philosophically speaking, if an error isn’t detected and the interpreter
//runs the code, is it really an error?
//
//
//Avoid crashing or hanging. Syntax errors are a fact of life, and
//language tools have to be robust in the face of them. Segfaulting or getting
//stuck in an infinite loop isn’t allowed. While the source may not be valid
//code, it’s still a valid input to the parser because users use the
//parser to learn what syntax is allowed.”
//
//
//“Those are the table stakes if you want to get in the parser game at all, but you
//really want to raise the ante beyond that. A decent parser should:
//
//
//Be fast. Computers are thousands of times faster than they were when
//parser technology was first invented. The days of needing to optimize your
//parser so that it could get through an entire source file during a coffee
//break are over. But programmer expectations have risen as quickly, if not
//faster. They expect their editors to reparse files in milliseconds after
//every keystroke.
//
//
//Report as many distinct errors as there are. Aborting after the first
//error is easy to implement, but it’s annoying for users if every time they
//fix what they think is the one error in a file, a new one appears. They
//want to see them all.
//
//
//Minimize cascaded errors. Once a single error is found, the parser no
//longer really knows what’s going on. It tries to get itself back on track
//and keep going, but if it gets confused, it may report a slew of ghost
//errors that don’t indicate other real problems in the code. When the first
//error is fixed, those phantoms[…]”
//
//Excerpt From
//Crafting Interpreters
//Robert Nystrom
//https://books.apple.com/de/book/crafting-interpreters/id1578795812?l=en-GB
//This material may be protected by copyright.
//
// Parser synchronization
// Is the process of discarding tokens until a known good state is reached.
// Errors on the discarded parsers won't be reported, which is a fair trade-off
//
// The traditional place in grammar to synchronize is between statements


// Grammar //
//
//“It’s called “recursive descent” because it walks down the grammar”
//
//Excerpt From
//Crafting Interpreters
//Robert Nystrom
//https://books.apple.com/de/book/crafting-interpreters/id1578795812?l=en-GB
//This material may be protected by copyright.


// MARK: - Grammar

// From Lower to Higher precedence
private enum BinaryExpression: CaseIterable {
  case comma // https://en.wikipedia.org/wiki/Comma_operator
  case equality
  case comparison
  case term
  case factor
  // then, unary

  var tokenTypesToMatch: [TokenType] {
    switch self {
    case .comma:
      return [
        .singleCharacter(.COMMA)
      ]
    case .equality:
      return [
        .oneOrTwoCharacter(.BANG_EQUAL),
        .oneOrTwoCharacter(.EQUAL_EQUAL)
      ]
    case .comparison:
      return [
        .oneOrTwoCharacter(.GREATER),
        .oneOrTwoCharacter(.GREATER_EQUAL),
        .oneOrTwoCharacter(.LESS),
        .oneOrTwoCharacter(.LESS_EQUAL)
      ]
    case .factor:
      return [
        .singleCharacter(.SLASH),
        .singleCharacter(.STAR)
      ]
    case .term:
      return [
        .singleCharacter(.MINUS),
        .singleCharacter(.PLUS)
      ]
    }
  }
}

// MARK: - Parser

final class Parser {
  private let tokens: [Token]
  private var currentIndex: Array.Index = 0

  init(tokens: [Token]) {
    self.tokens = tokens
  }

  func parse() -> Expression? {
    do {
      return try commaSeparatedExpressions()
    } catch is ParserError {
      print("unexpected error \(String(describing: error))")
      return nil
    } catch {
      print("unexpected error \(error)")
      return nil
    }
  }

  // MARK: - Binary operator rules

  private func commaSeparatedExpressions() throws -> Expression {
    try processBinaryExpression(type: .comma)
  }

  private func equality() throws -> Expression {
    try processBinaryExpression(type: .equality)
  }

  private func comparison() throws -> Expression {
    try processBinaryExpression(type: .comparison)
  }

  private func term() throws -> Expression {
    try processBinaryExpression(type: .term)
  }

  private func factor() throws -> Expression {
    try processBinaryExpression(type: .factor)
  }

  private func processBinaryExpression(
    type: BinaryExpression
  ) throws -> Expression {
    var expression = try nextExpression(for: type)

    while match(types: type.tokenTypesToMatch) {
      if type == .comma {
        expression = try nextExpression(for: type)
      } else {
        let `operator` = previous()
        let right = try nextExpression(for: type)
        expression = .binary(
          Expression.Binary(
            left: expression,
            operator: `operator`,
            right: right
          )
        )
      }
    }

    return expression
  }

  private func nextExpression(for binaryExpression: BinaryExpression) throws -> Expression {
    switch binaryExpression {
    case .comma:
      try equality()
    case .equality:
      try comparison()
    case .comparison:
      try term()
    case .term:
      try factor()
    case .factor:
      try unary()
    }
  }

  // MARK: - Unary operator rules

  private func unary() throws -> Expression {
    while match(types: .oneOrTwoCharacter(.BANG), .singleCharacter(.MINUS)) {
      let `operator` = previous()
      let right = try unary()
      return .unary(
        Expression.Unary(operator: `operator`, right: right)
      )
    }

    return try primary()
  }

  // highest precedence
  private func primary() throws -> Expression {
    if match(types: .keyword(.FALSE)) {
      return .literal(Expression.Literal(value: "false"))
    }
    if match(types: .keyword(.TRUE)) {
      return .literal(Expression.Literal(value: "true"))
    }
    if match(types: .keyword(.NIL)) {
      return .literal(Expression.Literal(value: "nil"))
    }
    if match(
      types: .literal(.NUMBER), .literal(.STRING)
    ) {
      return .literal(Expression.Literal(value: previous().literal?.description))
    }
    if match(types: .singleCharacter(.LEFT_PARENTHESIS)) {
      let expression = try commaSeparatedExpressions()
      try consume(
        type: .singleCharacter(.RIGHT_PARENTHESIS),
        message: "Expect ')' after expression."
      )
      return .grouping(
        Expression.Grouping(expression: expression)
      )
    }

    throw error(token: peek(), message: "Expect expression.")
  }

  // MARK: - Parser methods

  private func match(types: TokenType...) -> Bool {
    match(types: types)
  }

  private func match(types: [TokenType]) -> Bool {
    if types.contains(where: check(type:)) {
      advance()
      return true
    }
    return false
  }

  @discardableResult
  private func consume(
    type: TokenType,
    message: String
  ) throws -> Token {
    guard !check(type: type) else { return advance() }

    throw error(token: peek(), message: message)
  }

  private func check(type: TokenType) -> Bool {
    guard !isAtEnd() else { return false }

    return peek().type == type
  }

  @discardableResult
  private func advance() -> Token{
    if !isAtEnd() { currentIndex += 1 }

    return previous()
  }

  private func isAtEnd() -> Bool {
    peek().type == TokenType.EOF
  }

  private func peek() -> Token {
    tokens[currentIndex]
  }

  private func previous() -> Token {
    tokens[currentIndex - 1]
  }

  private func error(token: Token, message: String) -> ParserError {
    Lox.error(token: token, message: message)
    return ParserError(tokens: [token])
  }

  private func synchronize() {
    advance()

    while !isAtEnd() {
      guard previous().type != .singleCharacter(.SEMICOLON) else { return }

      // skip to the next statement boundary
      // and discard tokens that would have likely caused cascaded errors
      switch peek().type {
      case let .keyword(keywordType):
        switch keywordType {
        case .CLASS,
            .FUN,
            .VAR,
            .FOR,
            .IF,
            .WHILE,
            .PRINT,
            .RETURN:
          return
        default: break
        }
      default: break
      }

      advance()
    }
  }
}

struct ParserError: Error {
  let tokens: [Token]
}

// another way to handle common syntax errors is with *error productions*
// “You augment the grammar with a rule that successfully matches the erroneous
// syntax. The parser safely parses it but then reports it as an error instead of
// producing a syntax tree.

// “Error productions work well because you, the parser author, know how the code
// is wrong and what the user was likely trying to do. That means you can give a
// more helpful message to get the user back on track, like, “Unary ‘+’ expressions
// are not supported.” Mature parsers tend to accumulate error productions like
// barnacles since they help users fix common mistakes.
