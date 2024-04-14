//
//  Scanner.swift
//
//
//  Created by Marino Felipe on 22.04.22.
//

import Darwin

fileprivate let reservedKeywords: [String: TokenType.Keyword] = {
  [
    "and": .AND,
    "class": .CLASS,
    "else": .ELSE,
    "false": .FALSE,
    "for": .FOR,
    "fun": .FUN,
    "if": .IF,
    "nil": .NIL,
    "or": .OR,
    "print": .PRINT,
    "return": .RETURN,
    "super": .SUPER,
    "this": .THIS,
    "true": .TRUE,
    "var": .VAR,
    "while": .WHILE
  ]
}()

final class Scanner {
  private let source: String
  private var tokens: [Token] = []
  private var startIndex: String.Index
  private var currentIndex: String.Index
  private var line = 1

  init(source: String) {
    self.source = source
    startIndex = source.startIndex
    currentIndex = startIndex
  }

  func scanTokens() -> [Token] {
    while !isAtEnd() {
      // We are at the beginning of the next lexeme.
      startIndex = currentIndex
      scanToken()
    }

    tokens.append(.makeEndOfFile(line: line))

    return tokens
  }

  private func scanToken() {
    let nextCharacter = advance()

    switch nextCharacter {
    case "(":
      addToken(type: .singleCharacter(.LEFT_PARENTHESIS))
    case ")":
      addToken(type: .singleCharacter(.RIGHT_PARENTHESIS))
    case "{":
      addToken(type: .singleCharacter(.LEFT_BRACE))
    case "}":
      addToken(type: .singleCharacter(.RIGHT_BRACE))
    case ",":
      addToken(type: .singleCharacter(.COMMA))
    case ".":
      addToken(type: .singleCharacter(.DOT))
    case "-":
      addToken(type: .singleCharacter(.MINUS))
    case "+":
      addToken(type: .singleCharacter(.PLUS))
    case ";":
      addToken(type: .singleCharacter(.SEMICOLON))
    case "*":
      addToken(type: .singleCharacter(.STAR))
    case "!":
      addToken(
        type: .oneOrTwoCharacter(
          match(expected: "=") ? .BANG_EQUAL : .BANG
        )
      )
    case "=":
      addToken(
        type: .oneOrTwoCharacter(
          match(expected: "=") ? .EQUAL_EQUAL : .EQUAL
        )
      )
    case "<":
      addToken(
        type: .oneOrTwoCharacter(
          match(expected: "=") ? .LESS_EQUAL : .LESS
        )
      )
    case ">":
      addToken(
        type: .oneOrTwoCharacter(
          match(expected: "=") ? .GREATER_EQUAL : .GREATER
        )
      )
    case "/":
      if match(expected: "/") {
        // A comment goes until the end of the line.
        while peek() != "\n" && !isAtEnd() {
          advance()
        }
      } else if match(expected: "*") {
        commentBlock()
      } else {
        addToken(type: .singleCharacter(.SLASH))
      }
    case " ", "\r", "\t":
      // Ignore whitespace.
      break
    case "\n":
      line += 1
    case "\"":
      string()
    default:
      if nextCharacter.isDigit {
        number()
      } else if nextCharacter.isAlphaNumeric {
        identifier()
      } else {
        // TODO: Inject error reporting dependency if there's time for that :P
        // TOOD: Coalesce a run of invalid characters into a single error for a nicer UX
        Lox.error(line: line, message: "Unexpected character: \(nextCharacter)")
      }
    }
  } 

  private func commentBlock() {
    var commentBlockStack = 0

    enum BlockEvaluationResult {
      case blockStart
      case blockEnd
      case none
    }

    let blockEvaluation: () -> BlockEvaluationResult = {
      let currentCharacter = self.peek()
      let nextCharacter = self.peekNext()

      switch (currentCharacter, nextCharacter) {
      case ("/", "*"):
        return .blockStart
      case ("*", "/"):
        return .blockEnd
      default:
        return .none
      }
    }

    let advanceTwoForBlockStartOrEnd = {
      self.advance()
      self.advance()
    }

    while
      case let blockEvaluation = blockEvaluation(),
      (blockEvaluation != .blockEnd || commentBlockStack > 0)
        && !isAtEnd()
    {
      if blockEvaluation == .blockStart {
        commentBlockStack += 1

        // The opening /*
        advanceTwoForBlockStartOrEnd()
      } else if blockEvaluation == .blockEnd {
        commentBlockStack -= 1

        // The closing */
        advanceTwoForBlockStartOrEnd()
      } else {
        advance()
      }
    }

    // The closing */
    advanceTwoForBlockStartOrEnd()

    addToken(type: .oneOrTwoCharacter(.COMMENT_BLOCK))
  }

  private func identifier() {
    while peek().isAlphaNumeric {
      advance()
    }

    let text = source.substring(from: startIndex, to: currentIndex)
    let tokenType: TokenType = reservedKeywords[text].map(TokenType.keyword) ?? .literal(.IDENTIFIER)

    addToken(type: tokenType)
  }

  private func number() {
    let advanceWhileIsDigit = {
      while self.peek().isDigit {
        self.advance()
      }
    }

    advanceWhileIsDigit()

    // Look for a fractional part.
    if peek() == "." && peekNext().isDigit {
      // Consume the "."
      advance()

      advanceWhileIsDigit()
    }

    let stringValue = source.substring(from: startIndex, to: currentIndex)
    guard let value = Double(stringValue) else {
      Lox.error(line: line, message: "Unexpected invalid number.")
      return
    }

    addToken(type: .literal(.NUMBER), literal: .number(value))
  }

  private func string() {
    while peek() != "\"" && !isAtEnd() {
      if peek() == "\n" {
        line += 1
      }

      advance()
    }

    if isAtEnd() {
      Lox.error(line: line, message: "Unterminated string.")
      return
    }

    // The closing ".
    advance()

    // Trim the surrounding quotes.
    let value = source.substring(
      from: source.index(after: startIndex),
      to: source.index(before: currentIndex)
    )
    addToken(type: .literal(.STRING), literal: .string(value))
  }

  private func match(expected: Character) -> Bool {
    guard
      !isAtEnd(),
      source[currentIndex] == expected
    else {
      return false
    }

    currentIndex = source.index(after: currentIndex)
    return true
  }

  /// Like `advance` but does not consume the character, also known as lookahead
  private func peek() -> Character {
    if isAtEnd() {
      return .unicodeNull
    }

    return source[currentIndex]
  }

  private func peekNext() -> Character {
    if isAtEnd() {
      return .unicodeNull
    }

    return source[source.index(after: currentIndex)]
  }

  private func isAtEnd() -> Bool {
    currentIndex >= source.endIndex
  }

  @discardableResult
  private func advance() -> Character {
    defer {
      currentIndex = source.index(after: currentIndex)
    }
    
    return source[currentIndex]
  }

  private func addToken(type: TokenType) {
    addToken(type: type, literal: nil)
  }

  // TODO: Review separation of TokenType and LiteralType
  private func addToken(type: TokenType, literal: LiteralType?) {
    tokens.append(
      .init(
        type: type,
        lexeme: source.substring(from: startIndex, to: currentIndex),
        literal: literal,
        line: line
      )
    )
  }
}

private extension String {
  func substring(from: Index, to: Index) -> String {
    String(self[from..<to])
  }
}

private extension Character {
  static let unicodeNull = Self("\0")

  var isDigit: Bool {
    "0"..."9" ~= self
  }

  var isAlpha: Bool {
    "a"..."z" ~= self
    || "A"..."Z" ~= self
    || self == "_"
  }

  var isAlphaNumeric: Bool {
    isAlpha || isDigit
  }
}
