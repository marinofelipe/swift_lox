//
//  LiteralValue+Lox.swift
//  swift-lox
//
//  Created by Marino Felipe on 29.12.24.
//

extension LiteralValue: CustomStringConvertible {
  var description: String {
    switch self {
    case let .number(value):
      let stringValue = "\(value)"
      if stringValue.hasSuffix(".0") {
        return String(stringValue.dropLast(2))
      }
      return stringValue
    case let .string(value):
      return value.description
    case let .boolean(value):
      return value.description
    }
  }
}

extension Optional where Wrapped == LiteralValue {
  var stringified: String {
    switch self {
    case .none:
      "nil"
    case let .some(value):
      value.description
    }
  }
}

extension LiteralValue {
  var double: Double? {
    switch self {
    case let .number(value):
      return value
    default:
      return nil
    }
  }

  var string: String? {
    switch self {
    case let .string(value):
      return value
    default:
      return nil
    }
  }
}
