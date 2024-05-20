//
//  TokenType.swift
//
//
//  Created by Marino Felipe on 22.04.22.
//

enum TokenType: Equatable, CustomStringConvertible {
  enum SingleCharacter: String, Equatable {
    case LEFT_PARENTHESIS,
         RIGHT_PARENTHESIS,
         LEFT_BRACE,
         RIGHT_BRACE,
         COMMA,
         DOT,
         MINUS,
         PLUS,
         SEMICOLON,
         SLASH,
         STAR
  }

  enum OneOrTwoCharacter: String, Equatable {
    case BANG,
         BANG_EQUAL,
         COMMENT_BLOCK,
         EQUAL,
         EQUAL_EQUAL,
         GREATER,
         GREATER_EQUAL,
         LESS,
         LESS_EQUAL
  }

  enum Literal: String, Equatable {
    case IDENTIFIER,
         STRING,
         NUMBER
  }

  enum Keyword: String, Equatable {
    case AND,
         CLASS,
         ELSE,
         FALSE,
         FUN,
         FOR,
         IF,
         NIL,
         OR,
         PRINT,
         RETURN,
         SUPER,
         THIS,
         TRUE,
         VAR,
         WHILE
  }

  case singleCharacter(SingleCharacter)
  case oneOrTwoCharacter(OneOrTwoCharacter)
  case literal(Literal)
  case keyword(Keyword)
  case EOF

  var description: String {
    switch self {
    case let .singleCharacter(singleCharacter):
      return singleCharacter.rawValue
    case let .keyword(keyword):
      return keyword.rawValue
    case let .oneOrTwoCharacter(oneOrTwoCharacter):
      return oneOrTwoCharacter.rawValue
    case let .literal(literal):
      return literal.rawValue
    case .EOF:
      return "EOF"
    }
  }
}

enum LiteralType: Equatable, CustomStringConvertible {
  case string(String)
  case number(Double)

  var description: String {
    switch self {
    case let .number(value):
      return value.description
    case let .string(value):
      return value
    }
  }
}

struct Token: CustomStringConvertible, Equatable {
  let type: TokenType
  let lexeme: String
  let literal: LiteralType?
  let line: Int

  var description: String { "\(type) \(lexeme)" }

  static func makeEndOfFile(line: Int) -> Self {
    .init(
      type: .EOF,
      lexeme: "",
      literal: nil,
      line: line
    )
  }
}
