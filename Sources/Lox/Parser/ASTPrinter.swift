//
//  ASTPrinter.swift
//
//
//  Created by Marino Felipe on 19.05.24.
//

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
        expressions: binary.leftExpression, binary.rightExpression
      )
    case let .grouping(grouping):
      return parenthesize(
        name: "group",
        expressions: grouping.expression
      )
    case let .literal(literal):
      return literal.value.debugDescription
    case let .unary(unary):
      return parenthesize(
        name: unary.operator.lexeme,
        expressions: unary.rightExpression
      )
    case .invalid, .variable: // FIXME: implement variable case
      return "" // discarded
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

extension Optional where Wrapped == String {
  // overrides the default `debugDescription` conformance
  var debugDescription: String {
    switch self {
    case let .some(value):
      return value
    case .none:
      return "nil"
    }
  }
}
