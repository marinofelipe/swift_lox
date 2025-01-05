//
//  Expression+Visitor.swift
//  swift-lox
//
//  Created by Marino Felipe on 27.12.24.
//

extension Expression {
  protocol Visitor {
    func visitLiteralExpression(_: Expression.Literal) -> LiteralValue?
    func visitGroupingExpression(_: Expression.Grouping) throws -> LiteralValue?
    func visitUnaryExpression(_: Expression.Unary) throws -> LiteralValue?
    func visitBinaryExpression(_: Expression.Binary) throws -> LiteralValue?
    func visitVarExpression(_: Expression.Variable) throws -> LiteralValue
  }

  func accept(visitor: any Visitor) throws -> LiteralValue? {
    switch self {
    case let .literal(literal):
      visitor.visitLiteralExpression(literal)
    case let .unary(unary):
      try visitor.visitUnaryExpression(unary)
    case let .grouping(grouping):
      try visitor.visitGroupingExpression(grouping)
    case let .binary(binary):
      try visitor.visitBinaryExpression(binary)
    case let .variable(variable):
      try visitor.visitVarExpression(variable)
    case .invalid:
      nil
    }
  }
}
