//
//  ASTPrinter.swift
//
//
//  Created by Marino Felipe on 19.05.24.
//

final class ASTPrinter {
  func print(_ statements: [Statement]) {
    Swift.print(
      """
      \(ANSIColor.boldPurple.rawValue)>\(ANSIColor.default.rawValue) Here are the parsed AST statements and expressions
      
      \(statements.map { statement in
        self.prettyPrintedAST(for: statement)
      })
      """,
      terminator: "\n\n"
    )
  }

  func print(_ expression: Expression) {
    Swift.print(
      """
      \(ANSIColor.boldPurple.rawValue)>\(ANSIColor.default.rawValue) Here are the parsed AST statements and expressions:

      \(prettyPrintedAST(for: expression))
      """,
      terminator: "\n\n"
    )
  }

  private func prettyPrintedAST(for statement: Statement) -> String {
    switch statement {
    case let .print(printStatement):
      return "PRINT(\(prettyPrintedAST(for: printStatement.expression)))"
    case let .expr(expressionStatement):
      return "EXPRESSION(\(prettyPrintedAST(for: expressionStatement.expression)))"
    case let .var(varStatement):
      return "VAR(\(varStatement.initializer.map(prettyPrintedAST(for:)) ?? "empty declaration")"
    }
  }

  private func prettyPrintedAST(for expression: Expression) -> String {
    switch expression {
    case let .assign(_):
      fatalError()
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
    case let .variable(variable):
      return "VAR \(variable.name.lexeme)"
    case .invalid:
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

private extension Statement {
  var expression: Expression? {
    switch self {
    case let .expr(expressionStatement):
      expressionStatement.expression
    case let .print(printStatement):
      printStatement.expression
    case let .var(varExpression):
      varExpression.initializer
    }
  }
}
