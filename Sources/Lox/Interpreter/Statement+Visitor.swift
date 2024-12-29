//
//  Expression+Visitor.swift
//  swift-lox
//
//  Created by Marino Felipe on 27.12.24.
//

extension Statement {
  protocol Visitor {
    func visitExpressionStatement(_: Expr) throws
    func visitPrintStatement(_: Print) throws
  }

  func accept(visitor: any Visitor) throws {
    switch self {
    case let .expr(expression):
      try visitor.visitExpressionStatement(expression)
    case let .print(printExpression):
      try visitor.visitPrintStatement(printExpression)
    case let .var(varExpression):
      fatalError("tbi")
    }
  }
}
