//
//  Parser.swift
//
//
//  Created by Marino Felipe on 12.05.24.
//

// precedence lowest to highest

//  “The fact that the parser looks ahead at upcoming tokens to decide how to parse
//  puts recursive descent into the category of predictive parsers.”

//  “A parser really has two jobs:
//  Given a valid sequence of tokens, produce a corresponding syntax tree.
//  Given an invalid sequence of tokens, detect any errors and tell the
//  user about their mistakes.”

//  “Detect and report the error. If it doesn’t detect the error and passes the resulting   malformed syntax tree on
//  to the interpreter, all manner of horrors may be summoned.
//
//  Philosophically speaking, if an error isn’t detected and the interpreter
//  runs the code, is it really an error?
//
//
//  Avoid crashing or hanging. Syntax errors are a fact of life, and
//  language tools have to be robust in the face of them. Segfaulting or getting
//  stuck in an infinite loop isn’t allowed. While the source may not be valid
//  code, it’s still a valid input to the parser because users use the
//  parser to learn what syntax is allowed.”
//
//
//  “Those are the table stakes if you want to get in the parser game at all, but you
//  really want to raise the ante beyond that. A decent parser should:
//
//
//  Be fast. Computers are thousands of times faster than they were when
//  parser technology was first invented. The days of needing to optimize your
//  parser so that it could get through an entire source file during a coffee
//  break are over. But programmer expectations have risen as quickly, if not
//  faster. They expect their editors to reparse files in milliseconds after
//  every keystroke.
//
//
//  Report as many distinct errors as there are. Aborting after the first
//  error is easy to implement, but it’s annoying for users if every time they
//  fix what they think is the one error in a file, a new one appears. They
//  want to see them all.
//
//
//  Minimize cascaded errors. Once a single error is found, the parser no
//  longer really knows what’s going on. It tries to get itself back on track
//  and keep going, but if it gets confused, it may report a slew of ghost
//  errors that don’t indicate other real problems in the code. When the first
//  error is fixed, those phantoms[…]”
//
//  Excerpt From
//  Crafting Interpreters
//  Robert Nystrom
//  https://books.apple.com/de/book/crafting-interpreters/id1578795812?l=en-GB
//  This material may be protected by copyright.
//
//   Parser synchronization
//   Is the process of discarding tokens until a known good state is reached.
//   Errors on the discarded parsers won't be reported, which is a fair trade-off
//
//   The traditional place in grammar to synchronize is between statements


//   Grammar //
//
//  “It’s called “recursive descent” because it walks down the grammar”
//
//  Excerpt From
//  Crafting Interpreters
//  Robert Nystrom
//  https://books.apple.com/de/book/crafting-interpreters/id1578795812?l=en-GB
//  This material may be protected by copyright.

// MARK: - Grammar

// expression     → comma;
// comma          → assignment ( (",") assignment)*;
// assignment     → ternary = ternary;
// ternary        → equality ("?" expression : ":" expression)*;
// equality       → comparison ( ( "!=" | "==" ) comparison )* ;
// comparison     → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
// term           → factor ( ( "-" | "+" ) factor )* ;
// factor         → unary ( ( "/" | "*" ) unary )* ;
// unary          → ( "!" | "-" ) unary
//                | primary ;
// primary        → NUMBER | STRING | "true" | "false" | "nil"
//                | "(" expression ")" ;

// From Lower to Higher precedence
private enum BinaryExpression: CaseIterable {
  case comma // https://en.wikipedia.org/wiki/Comma_operator
  case assignment
  case ternary // not binary, here for now for simplicity
  case equality
  case comparison
  case term
  case factor
  // then, unary

  var tokenTypesToMatch: [TokenType] {
    switch self {
    case .comma:
      [
        .singleCharacter(.COMMA)
      ]
    case .assignment:
      [
        .oneOrTwoCharacter(.EQUAL)
      ]
    case .ternary:
      [
        .singleCharacter(.QUESTION_MARK) // only the opening
      ]
    case .equality:
      [
        .oneOrTwoCharacter(.BANG_EQUAL),
        .oneOrTwoCharacter(.EQUAL_EQUAL)
      ]
    case .comparison:
      [
        .oneOrTwoCharacter(.GREATER),
        .oneOrTwoCharacter(.GREATER_EQUAL),
        .oneOrTwoCharacter(.LESS),
        .oneOrTwoCharacter(.LESS_EQUAL)
      ]
    case .factor:
      [
        .singleCharacter(.SLASH),
        .singleCharacter(.STAR)
      ]
    case .term:
      [
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

  func parse() -> [Statement] {
    var statements = [Statement]()

    // recursive descent
    do {
      while !isAtEnd() {
        if let declaration = try declaration() {
          statements.append(declaration)
        }
      }
    } catch is ParserError {
      print("unexpected error \(String(describing: error))")
      return []
    } catch {
      print("unexpected error \(error)")
      return []
    }

    return statements
  }
}

// MARK: - Expressions

private extension Parser {
  
  // MARK: Binary operator rules

  func expression() throws -> Expression {
    try commaSeparatedExpressions()
  }

  func commaSeparatedExpressions() throws -> Expression {
    try processBinaryExpression(type: .comma)
  }

  func assignment() throws -> Expression {
    let expression = try ternary()

    if match(types: .oneOrTwoCharacter(.EQUAL)) {
      let equals = previous()
      let value = try assignment() // called to parse the right-hand side

      if case let .variable(varExpression) = expression {
        return .assign(
          Expression.Assign(
            name: varExpression.name,
            value: value
          )
        )
      }

      // The parser isn't in an invalid state, therefore an error is not thrown
      error(token: equals, message: "Invalid assignment target.")
    }

    return expression
  }

  func ternary() throws -> Expression {
    try processBinaryExpression(type: .ternary)
  }

  func equality() throws -> Expression {
    try processBinaryExpression(type: .equality)
  }

  func comparison() throws -> Expression {
    try processBinaryExpression(type: .comparison)
  }

  func term() throws -> Expression {
    try processBinaryExpression(type: .term)
  }

  func factor() throws -> Expression {
    try processBinaryExpression(type: .factor)
  }

  func processBinaryExpression(
    type: BinaryExpression
  ) throws -> Expression {
    var expression: Expression
    do {
      expression = try nextExpression(for: type)
    } catch {
      switch error as? ParserError {
      case .none:
        throw error
      case let .some(parserError):
        switch parserError.kind {
        case .regular:
          throw error
        case .binaryWithoutLeftHand:
          advance() // move on, discarding the right-hand operand
          return .invalid
        }
      }
    }

    while match(types: type.tokenTypesToMatch) {
      if type == .comma {
        expression = try nextExpression(for: type)
      } else if type == .ternary {
        return try processTernary(expression: expression)
      } else if type == .assignment {
        return try assignment()
      } else {
        let `operator` = previous()
        let right = try nextExpression(for: type)
        expression = .binary(
          Expression.Binary(
            leftExpression: expression,
            operator: `operator`,
            rightExpression: right
          )
        )
      }
    }

    return expression
  }

  func nextExpression(for binaryExpression: BinaryExpression) throws -> Expression {
    switch binaryExpression {
    case .comma:
      try assignment()
    case .assignment:
      try ternary()
    case .ternary:
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

  // TODO: Review associativity, should be RTL
  func processTernary(expression: Expression) throws -> Expression {
    let leftExpression = Expression.binary(
      Expression.Binary(
        leftExpression: expression,
        operator: previous(),
        rightExpression: try nextExpression(for: .ternary)
      )
    )
    try consume(type: .singleCharacter(.COLON), message: "Expected ':' for ternary expression.")
    let rightExpression = Expression.binary(
      Expression.Binary(
        leftExpression: leftExpression,
        operator: previous(),
        rightExpression: try nextExpression(for:  .ternary)
      )
    )
    return rightExpression
  }

  // MARK: Unary operator rules

  func unary() throws -> Expression {
    while match(types: .oneOrTwoCharacter(.BANG), .singleCharacter(.MINUS)) {
      let `operator` = previous()
      let right = try unary()
      return .unary(
        Expression.Unary(operator: `operator`, rightExpression: right)
      )
    }

    return try primary()
  }

  // highest precedence

  func primary() throws -> Expression {
    if match(types: .keyword(.FALSE)) {
      return .literal(Expression.Literal(value: .boolean(false)))
    }
    if match(types: .keyword(.TRUE)) {
      return .literal(Expression.Literal(value: .boolean(true)))
    }
    if match(types: .keyword(.NIL)) {
      return .literal(Expression.Literal(value: .none))
    }
    if match(
      types: .literal(.NUMBER), .literal(.STRING)
    ) {
      if let previousLiteral = previous().literal {
        return .literal(Expression.Literal(value: .init(from: previousLiteral)))
      } else {
        return .literal(Expression.Literal(value: .none))
      }
    }
    if match(types: .literal(.IDENTIFIER)) {
      return .variable(Expression.Variable(name: previous()))
    }
    if match(types: .singleCharacter(.LEFT_PARENTHESIS)) {
      let expression = try expression()
      try consume(
        type: .singleCharacter(.RIGHT_PARENTHESIS),
        message: "Expect ')' after expression."
      )
      return .grouping(
        Expression.Grouping(expression: expression)
      )
    }

    let allBinaryOperators = BinaryExpression.allCases
      .map(\.tokenTypesToMatch)
      .reduce([], +)
    try allBinaryOperators.forEach { binaryOperator in
      if check(type: binaryOperator) {
        throw self.error(
          token: peek(),
          message: "Didn't find a left-hand operand",
          kind: .binaryWithoutLeftHand
        )
      }
    }

    throw error(token: peek(), message: "Expect expression.")
  }
}

// MARK: - Statements

private extension Parser {
  func declaration() throws -> Statement? {
    do {
      if match(types: .keyword(.VAR)) {
        return try varDeclaration()
      }
      
      return try statement()
    } catch {
      synchronize()
      return nil
    }
  }

  func statement() throws -> Statement {
    if match(types: .keyword(.PRINT)) {
      return try printStatement()
    }

    return try expressionStatement()
  }

  func varDeclaration() throws -> Statement {
    let name = try consume(type: .literal(.IDENTIFIER), message: "Expect variable name.")

    var initializer: Expression?
    if match(types: .oneOrTwoCharacter(.EQUAL)) {
      initializer = try expression()
    }

    try consume(
      type: .singleCharacter(.SEMICOLON),
      message: "Expect ';' after variable declaration."
    )

    return .var(Statement.Var(name: name, initializer: initializer))
  }

  func printStatement() throws -> Statement {
    let value = try expression()
    try consume(type: .singleCharacter(.SEMICOLON), message: "Expect ';' after value.")

    return .print(Statement.Print(expression: value))
  }

  func expressionStatement() throws -> Statement {
    let value = try expression()
    try consume(type: .singleCharacter(.SEMICOLON), message: "Expect ';' after expression.")

    return .expr(Statement.Expr(expression: value))
  }
}

// MARK: - Parser methods

private extension Parser {
  func match(types: TokenType...) -> Bool {
    match(types: types)
  }

  func match(types: [TokenType]) -> Bool {
    if types.contains(where: check(type:)) {
      advance()
      return true
    }
    return false
  }

  @discardableResult
  func consume(
    type: TokenType,
    message: String
  ) throws -> Token {
    guard !check(type: type) else { return advance() }

    throw error(token: peek(), message: message)
  }

  func check(type: TokenType) -> Bool {
    guard !isAtEnd() else { return false }

    return peek().type == type
  }

  @discardableResult
  func advance() -> Token{
    if !isAtEnd() { currentIndex += 1 }

    return previous()
  }

  func isAtEnd() -> Bool {
    peek().type == TokenType.EOF
  }

  func peek() -> Token {
    tokens[currentIndex]
  }

  func previous() -> Token {
    tokens[currentIndex - 1]
  }

  @discardableResult
  func error(
    token: Token,
    message: String,
    kind: ParserError.Kind = .regular
  ) -> ParserError {
    Lox.error(token: token, message: message)
    return ParserError(tokens: [token], kind: kind)
  }

  func synchronize() {
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

// MARK: - Types and extensions

struct ParserError: Error {
  enum Kind: Equatable {
    case regular
    case binaryWithoutLeftHand
  }

  let tokens: [Token]
  let kind: Kind

  init(
    tokens: [Token],
    kind: Kind = .regular
  ) {
    self.tokens = tokens
    self.kind = kind
  }
}

extension LiteralValue {
  init(from literal: LiteralType) {
    switch literal {
    case let .boolean(value):
      self = .boolean(value)
    case let .number(value):
      self = .number(value)
    case let .string(value):
      self = .string(value)
    }
  }
}

// another way to handle common syntax errors is with *error productions*
// “You augment the grammar with a rule that successfully matches the erroneous
// syntax. The parser safely parses it but then reports it as an error instead of
// producing a syntax tree.
//
// “Error productions work well because you, the parser author, know how the code
// is wrong and what the user was likely trying to do. That means you can give a
// more helpful message to get the user back on track, like, “Unary ‘+’ expressions
// are not supported.” Mature parsers tend to accumulate error productions like
// barnacles since they help users fix common mistakes.
//
//  Excerpt From
//  Crafting Interpreters
//  Robert Nystrom
//  https://books.apple.com/de/book/crafting-interpreters/id1578795812?l=en-GB
//  This material may be protected by copyright.
