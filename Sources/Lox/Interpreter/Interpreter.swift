//
//  Interpreter.swift
//
//
//  Created by Marino Felipe on 18.04.22.
//

import Foundation

//“Code like this is weird, so C, Java, and friends all disallow it. It’s as if
//there are two levels of “precedence” for statements.
//Some places where a statement is allowed—like inside a block or at the top
//level—allow any kind of statement, including declarations. Others allow only
//the “higher” precedence statements that don’t declare names.”

//Program        → declaration* EOF ;
//
//declaration    → varDecl
//               | statement ;
//
//statement      → exprStmt
//               | printStmt ;”

/// A **post-order traversal** interpreter. Each node evaluates its children before doing its own work.
final class Interpreter { // Runtime, while Parser is compile-time
  func interpret(statements: [Statement]) {
    do {
      try statements.forEach(execute(statement:))
    } catch {
      guard let runtimeError = error as? RuntimeError else { return } // should it be handled?
      Lox.runtimeError(runtimeError)
    }
  }
}

private extension Interpreter {
  @discardableResult
  func evaluate(expression: Expression) throws -> LiteralValue? {
    try expression.accept(visitor: self)
  }

  func execute(statement: Statement) throws {
    try statement.accept(visitor: self)
  }
}

// MARK: - Expression.Visitor

extension Interpreter: Expression.Visitor {
  func visitLiteralExpression(_ expression: Expression.Literal) -> LiteralValue? {
    expression.value
  }

  func visitUnaryExpression(_ expression: Expression.Unary) throws -> LiteralValue? {
    let rightExpression = try evaluate(expression: expression.rightExpression)

    switch expression.operator.type {
    case .oneOrTwoCharacter(.BANG):
      return rightExpression.isTruthy
    case .singleCharacter(.MINUS):

      switch rightExpression {
      // is that as a dynamically typed lang? May need to runtime crash instead
      case let .number(double):
        return .number(double)
      default:
        // Error out?
        return nil
      }
    default:
      // Unreachable.
      return nil
    }
  }

  //  “Some parsers don’t define tree nodes for parentheses. Instead, when parsing a
  //  parenthesized expression, they simply return the node for the inner expression.
  //  We do create a node for parentheses in Lox because we’ll need it later to
  //  correctly handle the left-hand sides of assignment expressions.”
  func visitGroupingExpression(_ expression: Expression.Grouping) throws -> LiteralValue? {
    try evaluate(expression: expression.expression)
  }

  func visitBinaryExpression(_ expression: Expression.Binary) throws -> LiteralValue? {
    let leftExpression = try evaluate(expression: expression.leftExpression)
    let rightExpression = try evaluate(expression: expression.rightExpression)

    switch expression.operator.type {
      // arithmetic operators - produce the operand value
    case .singleCharacter(.MINUS):
      guard
        let leftDouble = leftExpression?.double,
        let rightDouble = rightExpression?.double
      else {
        throw RuntimeError(token: expression.operator, message: "Both operands must be numbers.")
      }

      return .number(leftDouble - rightDouble)
    case .singleCharacter(.PLUS):
      if
        let leftDouble = leftExpression?.double,
        let rightDouble = rightExpression?.double
      {
        return .number(leftDouble + rightDouble)
      } else if
        let leftString = leftExpression?.string,
        let rightString = rightExpression?.string
      {
        return .string(leftString + rightString)
      }

      switch (leftExpression?.string, rightExpression?.string) {
      case let (.some(leftValue), .some(rightValue)):
        return .string(leftValue + rightValue)
      case let (.some(leftValue), .none):
        return .string(leftValue + rightExpression.stringified)
      case let (.none, .some(rightValue)):
        return .string(leftExpression.stringified + rightValue)
      case (.none, .none):
        throw RuntimeError(
          token: expression.operator,
          message: "Operands must be two numbers, two strings or convertible to string."
        )
      }
    case .singleCharacter(.SLASH):
      guard
        let leftDouble = leftExpression?.double,
        let rightDouble = rightExpression?.double
      else {
        throw RuntimeError(token: expression.operator, message: "Both operands must be numbers.")
      }

      guard !rightDouble.isZero else {
        throw RuntimeError(token: expression.operator, message: "Attempted to divide by zero")
      }

      return .number(leftDouble / rightDouble)
    case .singleCharacter(.STAR):
      guard
        let leftDouble = leftExpression?.double,
        let rightDouble = rightExpression?.double
      else {
        throw RuntimeError(token: expression.operator, message: "Both operands must be numbers.")
      }

      return .number(leftDouble * rightDouble)

    // comparison operators - produce Bool
    case .oneOrTwoCharacter(.GREATER):
      guard
        let leftDouble = leftExpression?.double,
        let rightDouble = rightExpression?.double
      else {
        throw RuntimeError(token: expression.operator, message: "Both operands must be numbers.")
      }

      return .boolean(leftDouble > rightDouble)
    case .oneOrTwoCharacter(.GREATER_EQUAL):
      guard
        let leftDouble = leftExpression?.double,
        let rightDouble = rightExpression?.double
      else {
        throw RuntimeError(token: expression.operator, message: "Both operands must be numbers.")
      }

      return .boolean(leftDouble >= rightDouble)
    case .oneOrTwoCharacter(.LESS):
      guard
        let leftDouble = leftExpression?.double,
        let rightDouble = rightExpression?.double
      else {
        throw RuntimeError(token: expression.operator, message: "Both operands must be numbers.")
      }

      return .boolean(leftDouble < rightDouble)
    case .oneOrTwoCharacter(.LESS_EQUAL):
      guard
        let leftDouble = leftExpression?.double,
        let rightDouble = rightExpression?.double
      else {
        throw RuntimeError(token: expression.operator, message: "Both operands must be numbers.")
      }

      return .boolean(leftDouble <= rightDouble)

    // equality operators - produce Bool
    case .oneOrTwoCharacter(.BANG_EQUAL):
      return leftExpression.isEqual(to: rightExpression, not: true)
    case .oneOrTwoCharacter(.EQUAL_EQUAL):
      return leftExpression.isEqual(to: rightExpression)
    default:
      // Unreachable.
      return nil
    }
  }
}

// MARK: - Statement.Visitor

extension Interpreter: Statement.Visitor {
  func visitExpressionStatement(_ statement: Statement.Expr) throws {
    try evaluate(expression: statement.expression)
  }
  
  func visitPrintStatement(_ statement: Statement.Print) throws {
    let value = try evaluate(expression: statement.expression)
    print(value.stringified)
  }
}

// MARK: - LiteralValue helpers

private extension Optional where Wrapped == LiteralValue {
  var isTruthy: LiteralValue {
    switch self {
    case let .boolean(boolValue):
      .boolean(boolValue)
    case .none:
      .boolean(false)
    default:
      .boolean(true) // why, again?
    }
  }

  func isEqual(to other: Self, not: Bool = false) -> LiteralValue {
    switch (self, other) {
    case (.none, .none):
      .boolean(not ? false : true)
    case (.none, _), (_, .none):
      .boolean(not ? true : false)
    case let (.some(lhsSome), .some(rhsSome)):
      .boolean(not ? lhsSome != rhsSome : lhsSome == rhsSome)
    }
  }
}
