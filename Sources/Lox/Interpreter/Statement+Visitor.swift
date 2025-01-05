//
//  Expression+Visitor.swift
//  swift-lox
//
//  Created by Marino Felipe on 27.12.24.
//

extension Statement {
  protocol Visitor {
    func visitPrintStatement(_: Print) throws
    func visitExpressionStatement(_: Expr) throws
    func visitVarStatement(_: Var) throws
  }

  func accept(visitor: any Visitor) throws {
    switch self {
    case let .print(printExpression):
      try visitor.visitPrintStatement(printExpression)
    case let .expr(expression):
      try visitor.visitExpressionStatement(expression)
    case let .var(varExpression):
      try visitor.visitVarStatement(varExpression)
    }
  }
}
