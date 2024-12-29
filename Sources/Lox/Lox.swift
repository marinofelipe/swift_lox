//
//  Lox.swift
//
//
//  Created by Marino Felipe on 18.04.22.
//

import Foundation

public enum Lox {
  private static let interpreter = Interpreter()
  private static var hadError = false
  private static var hadRuntimeError = false

  public static func main(args: [String]) throws {
    if args.count > 1 {
      print("Usage: swift_lox [script]")
      exit(64)
    } else if args.count == 1 {
      try runFile(path: args[0])
    } else {
      try runPrompt()
    }
  }

  private static func runFile(path: String) throws {
    let fileContents = try String(contentsOfFile: path, encoding: .utf8)
    run(source: fileContents)

    if hadError {
      exit(65)
    } else if hadRuntimeError {
      exit(70)
    }
  }

  private static func runPrompt() throws {
    print(
      """
      \(ANSIColor.boldPurple.rawValue)Welcome to swift-lox

      \(ANSIColor.default.rawValue)A swift based lox interpreter

      Have fun :D ..
      """,
      terminator: "\n\n"
    )

    while let inputLine = readLine(strippingNewline: true) {
      print(
        "\n\(ANSIColor.boldPurple.rawValue)>\(ANSIColor .default.rawValue) ",
        terminator: ""
      )

      guard inputLine.isEmpty == false else {
        break
      }

      run(source: inputLine)
      hadError = false
    }
  }

  private static func run(source: String) {
    let scanner = Scanner(source: source)
    let tokens = scanner.scanTokens()

    print("Here are the Scanner generated tokens:", terminator: "\n\n")
    print(tokens.map(\.description).joined(separator: "\n"))
    print("\n")

    let parser = Parser(tokens: tokens)
    let statements = parser.parse()

    // stop if there are syntax errors
    guard !statements.isEmpty, !hadError else { return }

    #if DEBUG
    let astPrinter = ASTPrinter()
    statements.forEach { statement in
      astPrinter.print(statement.expression)
    }
    #endif

    interpreter.interpret(statements: statements)
  }

  static func error(line: Int = #line, message: String) {
    report(line: line, where: "", message: message)
  }

  private static func report(
    line: Int,
    where: String,
    message: String
  ) {
    print("[line \(line)] Error \(`where`): \(message)", terminator: "\n")
    hadError = true
  }

  static func error(token: Token, message: String) {
    report(
      line: token.line,
      where: token.type == TokenType.EOF ? " at end" : " at '" + token.lexeme + "'",
      message: message
    )
  }

  static func runtimeError(_ error: RuntimeError) {
    print("\(error.message)\n[line \(error.token.line)]", terminator: "\n")
    hadRuntimeError = true
  }
}

private extension Statement {
  var expression: Expression {
    switch self {
    case let .expr(expressionStatement):
      return expressionStatement.expression
    case let .print(printStatement):
      return printStatement.expression
    }
  }
}
