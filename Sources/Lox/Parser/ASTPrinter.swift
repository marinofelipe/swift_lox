//
//  ASTPrinter.swift
//
//
//  Created by Marino Felipe on 19.05.24.
//

// TODO: Review
extension Expression.Binary: CustomDebugStringConvertible {
  var debugDescription: String {
    "\(`operator`) \(`left`) \(`right`)"
  }
}

extension Expression.Grouping: CustomDebugStringConvertible {
  var debugDescription: String {
    "grouping(\(expression))"
  }
}

extension Expression.Literal: CustomDebugStringConvertible {
  var debugDescription: String { value ?? "nil" }
}

extension Expression.Unary: CustomDebugStringConvertible {
  var debugDescription: String {
    "\(`operator`) \(`right`)"
  }
}

extension Expression: CustomDebugStringConvertible {
  var debugDescription: String {
    switch self {
    case let .binary(binary):
      return binary.debugDescription
    case let .grouping(expression):
      return expression.debugDescription
    case let .literal(literal):
      return literal.debugDescription
    case let .unary(unary):
      return unary.debugDescription
    }
  }
}

final class ASTPrinter {
  func print(_ expression: Expression) {
    Swift.print(
      """
      \(ANSIColor.boldPurple.rawValue)>\(ANSIColor.default.rawValue) Here are the parsed AST expressions:

      \(prettyPrintedAST(for: expression))
      """,
      terminator: "\n\n"
    )
  }

  private func prettyPrintedAST(for expression: Expression) -> String {
    switch expression {
    case let .binary(binary):
      return parenthesize(
        name: binary.`operator`.lexeme,
        expressions: binary.left, binary.right
      )
    case let .grouping(grouping):
      return parenthesize(
        name: "group",
        expressions: grouping.expression
      )
    case let .literal(literal):
      return literal.debugDescription
    case let .unary(unary):
      return parenthesize(
        name: unary.operator.lexeme,
        expressions: unary.right
      )
    }
  }

  private func parenthesize(
    name: String,
    expressions: Expression...
  ) -> String {
    "("
    + name
    + expressions.map { " " + prettyPrintedAST(for: $0) }.joined(separator: "")
    + ")"
  }
}
