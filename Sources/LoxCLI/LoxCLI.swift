//
//  LoxCLI.swift
//
//
//  Created by Marino Felipe on 18.04.22.
//

import ArgumentParser
import Foundation
import Lox

public struct LoxCLI: ParsableCommand {
  @Option(
    name: [
      .long,
      .customLong("path"),
      .customLong("file"),
      .short
    ],
    help: "A relative or absolute file path that contains lox code to be executed"
  )
  var filePath: URL?

  @Flag(
    wrappedValue: false,
    name: [
      .long,
      .customLong("tokens"),
    ],
    help: """
    Whether or not the Scanner generated tokens should be printed. 
    Useful for debugging the Interpreter.
    """
  )
  var debugTokens: Bool

  @Flag(
    wrappedValue: false,
    name: [
      .long,
      .customLong("ast"),
    ],
    help: """
    Whether or not the Parser generated AST should be printed. 
    Useful for debugging the Interpreter.
    """
  )
  var debugAST: Bool

  public init() {}

  public func run() throws {
    try Lox.main(
      runFilePath: filePath?.absoluteString,
      debugTokens: debugTokens,
      debugAST: debugAST
    )
  }
}

extension URL: @retroactive ExpressibleByArgument {
  public init?(argument: String) {
    self.init(string: argument)
  }
}
