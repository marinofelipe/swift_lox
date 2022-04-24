//
//  TokenType.swift
//  
//
//  Created by Marino Felipe on 22.04.22.
//

enum TokenType: Equatable {
    enum SingleCharacter: Equatable {
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

    enum OneOrTwoCharacter: Equatable {
        case BANG,
             BANG_EQUAL,
             EQUAL,
             EQUAL_EQUAL,
             GREATER,
             GREATER_EQUAL,
             LESS,
             LESS_EQUAL
    }

    enum Literal: Equatable {
        case IDENTIFIER,
             STRING,
             NUMBER
    }

    enum Keyword: Equatable {
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
}

enum LiteralType: Equatable {
    case string(String)
    case number(Double)
}

struct Token: CustomStringConvertible {
    let type: TokenType
    let lexeme: String
    let literal: LiteralType?
    let line: Int

    var description: String {
        "\(type) \(lexeme) \(literal ?? .string("none"))"
    }

    static func makeEndOfFile(line: Int) -> Self {
        .init(
            type: .EOF,
            lexeme: "",
            literal: nil,
            line: line
        )
    }
}
