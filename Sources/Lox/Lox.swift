//
//  Lox.swift
//
//
//  Created by Marino Felipe on 18.04.22.
//

import Foundation

public enum Lox {
  private static var hadError = false

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
    }
  }

  private static func runPrompt() throws {
    print("""
        \(ANSIColor.boldPurple.rawValue)Welcome to swift-lox

        \(ANSIColor.default.rawValue)A swift based lox interpreter

        Have fun :)...
        """
    )

    while let inputLine = readLine(strippingNewline: true) {
      print(
        "\(ANSIColor.boldPurple.rawValue)>\(ANSIColor .default.rawValue)",
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

    print("Here are the Scanner generated tokens:", terminator: "\n")
    print(tokens.map(\.description).joined(separator: "\n"))
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
}
