//
//  Interpreter.swift
//
//
//  Created by Marino Felipe on 18.04.22.
//

import Foundation

protocol InterpreterVisitor {
  associatedtype T

  func visitLiteralExpression(_: Expression.Literal) -> T
  func visitGroupingExpression(_: Expression.Grouping) -> T
  func visitUnaryExpression(_: Expression.Unary) throws -> T?
  func visitBinaryExpression(_: Expression.Binary) throws -> T?
}

/// A **post-order traversal** interpreter. Each node evaluates its children before doing its own work.
final class Interpreter: InterpreterVisitor {
  func interpret(expression: Expression) {
    do {
      let value = try evaluate(expression: expression)
      print(stringify(value))
    } catch {
      guard let runtimeError = error as? RuntimeError else { return } // should it be handled?
      Lox.runtimeError(runtimeError)
    }
  }

  func visitLiteralExpression(_ expression: Expression.Literal) -> Any {
    expression.value as Any
  }

  func visitUnaryExpression(_ expression: Expression.Unary) throws -> T? {
    let rightExpression = try evaluate(expression: expression.rightExpression)

    switch expression.operator.type {
    case .oneOrTwoCharacter(.BANG):
      return isTruthy(rightExpression)
    case .singleCharacter(.MINUS):
      return -(rightExpression as! Double)
    default:
      // Unreachable.
      return nil
    }
  }

  private func checkNumberOperand(operator: Token, operand: AnyObject?) throws {
    guard !(operand is Double) else { return }
    throw RuntimeError(token: `operator`, message: "Operand must be a number.")
  }

  private func checkNumberOperands(
    operator: Token,
    left: AnyObject?,
    right: AnyObject?
  ) throws {
    guard !(left is Double && right is Double) else { return }
    throw RuntimeError(token: `operator`, message: "Both operands must be numbers.")
  }

  private func isTruthy(_ object: AnyObject?) -> Bool {
    switch object {
    case is Bool:
      return object as? Bool == false
    case .none:
      return false
    default:
      return true
    }
  }

  private func isEqual(_ lhs: AnyObject?, rhs: AnyObject?) -> Bool {
    switch (lhs, rhs) {
    case (.none, .none):
      return true
    case (.none, _), (_, .none):
      return false
    case let (.some(lhsSome), .some(rhsSome)):
      return lhsSome.isEqual(to: rhsSome)
    }
  }

  private func stringify(_ object: AnyObject?) -> String {
    switch object {
    case .none:
      return "nil"
    case let .some(value):
      switch value {
      case is Double:
        let stringValue = "\(value)"
        if stringValue.hasSuffix(".0") {
          return String(stringValue.dropLast(2))
        }
        return stringValue
      default:
        return "\(value)"
      }
    }
  }

  //  “Some parsers don’t define tree nodes for parentheses. Instead, when parsing a
  //  parenthesized expression, they simply return the node for the inner expression.
  //  We do create a node for parentheses in Lox because we’ll need it later to
  //  correctly handle the left-hand sides of assignment expressions.”
  func visitGroupingExpression(_ expression: Expression.Grouping) -> T {
    expression.expression // expression contained inside the parenthesis
    // return evaluate(expression.expression)
  }

  private func evaluate(expression: Expression) throws -> AnyObject? {
//    expression.accept(self)
    fatalError("tbi")
  }

  func visitBinaryExpression(_ expression: Expression.Binary) throws -> T? {
    let leftExpression = try evaluate(expression: expression.leftExpression)
    let rightExpression = try evaluate(expression: expression.rightExpression)

    // lox is a dynamically typed language, so it will crash in runtime
    // TODO: Evolve it to report a runtime error when the types doesn't match
    let doubleLeft = leftExpression as! Double
    let doubleRight = rightExpression as! Double

    switch expression.operator.type {
      // arithmetic operators - produce the operand value
    case .singleCharacter(.MINUS):
      try checkNumberOperands(
        operator: expression.operator,
        left: leftExpression,
        right: rightExpression
      )
      return doubleLeft - doubleRight
    case .singleCharacter(.PLUS):
      if
        let leftDouble = leftExpression as? Double,
          let rightDouble = rightExpression as? Double
      {
        return leftDouble + rightDouble
      } else if
        let leftString = leftExpression as? String,
        let rightString = rightExpression as? String
      {
        return leftString + rightString
      }

      throw RuntimeError(
        token: expression.operator,
        message: "Operands must be two numbers or two strings."
      )
    case .singleCharacter(.SLASH):
      try checkNumberOperands(
        operator: expression.operator,
        left: leftExpression,
        right: rightExpression
      )
      return doubleLeft / doubleRight
    case .singleCharacter(.STAR):
      try checkNumberOperands(
        operator: expression.operator,
        left: leftExpression,
        right: rightExpression
      )
      return doubleLeft * doubleRight

    // comparison operators - produce Bool
    case .oneOrTwoCharacter(.GREATER):
      try checkNumberOperands(
        operator: expression.operator,
        left: leftExpression,
        right: rightExpression
      )
      return doubleLeft > doubleRight
    case .oneOrTwoCharacter(.GREATER_EQUAL):
      try checkNumberOperands(
        operator: expression.operator,
        left: leftExpression,
        right: rightExpression
      )
      return doubleLeft >= doubleRight
    case .oneOrTwoCharacter(.LESS):
      try checkNumberOperands(
        operator: expression.operator,
        left: leftExpression,
        right: rightExpression
      )
      return doubleLeft < doubleRight
    case .oneOrTwoCharacter(.LESS_EQUAL):
      try checkNumberOperands(
        operator: expression.operator,
        left: leftExpression,
        right: rightExpression
      )
      return doubleLeft <= doubleRight

    // equality operators - produce Bool
    case .oneOrTwoCharacter(.BANG_EQUAL):
      return !isEqual(leftExpression, rhs: rightExpression)
    case .oneOrTwoCharacter(.EQUAL_EQUAL):
      return isEqual(leftExpression, rhs: rightExpression)
    default:
      // Unreachable.
      return nil
    }
  }
}
