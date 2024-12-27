//
//  LoxAST.swift
//
//
//  Created by Marino Felipe on 01.04.24.
//

import ArgumentParser
import Foundation
import TSCBasic

@main
struct LoxAST: ParsableCommand {
  @Option(help: "The relative path to where the generated files will be created")
  var outputDir: String

  func run() throws {
    try GenerateAST.main(outputDir: outputDir)
  }
}

enum GenerateAST {
  enum ASTType: String {
    case expression = "Expression"
    case statement = "Statement"
  }

  public static func main(outputDir: String) throws {
    try defineExpressionAST(outputDir: outputDir)
    try defineStatementAST(outputDir: outputDir)
  }

  private static func defineExpressionAST(outputDir: String) throws {
    try defineAST(
      for: .expression,
      outputDir: outputDir,
      types: [
        // Using my own notation/form with `;` so that `:` can be only used for the typed properties
        "Binary   ; leftExpression: Expression, `operator`: Token, rightExpression: Expression",
        "Grouping ; expression: Expression",
        "Literal  ; value: LiteralValue?",
        "Unary    ; `operator`: Token, rightExpression: Expression",
        "Invalid"
      ]
    )
  }

  private static func defineStatementAST(outputDir: String) throws {
    try defineAST(
      for: .statement,
      outputDir: outputDir,
      types: [
        // Using my own notation/form with `;` so that `:` can be only used for the typed properties
        "Expr   ; expression: Expression",
        "Print ; expression: Expression",
      ]
    )
  }

  private static func defineAST(
    for astType: ASTType,
    outputDir: String,
    types: [String]
  ) throws {
    let baseName = astType.rawValue
    let fileURL = try AbsolutePath(validating: outputDir)
      .appending(component: "\(baseName).swift")

    if !FileManager.default.fileExists(atPath: fileURL.pathString) {
      FileManager.default.createFile(atPath: fileURL.pathString, contents: nil)
    }

    if let fileHandle = FileHandle(forWritingAtPath: fileURL.pathString) {
      try fileHandle.truncate(atOffset: 0) // clear before proceeding

      fileHandle.write("import Foundation\n\n".data(using: .utf8)!)

      let enumType = astType == .expression ? "indirect " : ""
      fileHandle.write("\(enumType)enum \(baseName): Equatable {\n".data(using: .utf8)!)

      fileHandle.write("  // The AST cases.\n".data(using: .utf8)!)

      struct ClassAndProperties: Equatable {
        let className: String
        let properties: [String]
      }

      let classes: [ClassAndProperties] = types.compactMap { type in
        let typeSplit = type.split(separator: ";")

        guard
          typeSplit.count <= 2, // 1 for the invalid case
          let className = typeSplit.first.map(String.init)
        else {
          return nil
        }

        let propertiesString = typeSplit.count == 2
        ? typeSplit.last.map(String.init)
        : nil

        let properties = propertiesString?
          .split(separator: ",")
          .map(String.init)
        ?? []

        return ClassAndProperties(
          className: className.replacingOccurrences(of: " ", with: ""),
          properties: properties
        )
      }

      classes.forEach {
        defineCase(
          fileHandle: fileHandle,
          baseName: baseName,
          className: $0.className,
          fields: $0.properties
        )
      }

      fileHandle.write("\n".data(using: .utf8)!)

      classes.forEach {
        defineType(
          fileHandle: fileHandle,
          className: $0.className,
          fields: $0.properties
        )
        if $0 != classes.last {
          fileHandle.write("\n".data(using: .utf8)!)
        }
      }

      fileHandle.write("}\n".data(using: .utf8)!)

      if astType == .expression {
        defineLiteralEnum(fileHandle: fileHandle)
      }

      fileHandle.closeFile()
    }
  }

  private static func defineCase(
    fileHandle: FileHandle,
    baseName: String,
    className: String,
    fields: [String]
  ) {
    if fields.isEmpty {
      fileHandle.write(
        "  case \(className.lowercased())\n"
          .data(using: .utf8)!
      )
    } else {
      fileHandle.write(
        "  case \(className.lowercased())(\(className))\n"
          .data(using: .utf8)!
      )
    }
  }

  private static func defineType(
    fileHandle: FileHandle,
    className: String,
    fields: [String]
  ) {
    guard !fields.isEmpty else { return }

    fileHandle.write(
      "  struct \(className): Equatable {\n"
        .data(using: .utf8)!
    )
    for field in fields {
      fileHandle.write(
        "    let\(field)\n"
          .data(using: .utf8)!
      )
    }
    fileHandle.write(
      "  }\n"
        .data(using: .utf8)!
    )
  }

  private static func defineLiteralEnum(fileHandle: FileHandle) {
    fileHandle.write(
      """
      
      enum LiteralValue: Equatable {
        case string(String)
        case number(Double)
        case boolean(Bool)
      }
      """
      .data(using: .utf8)!
    )
  }
}
