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
  public static func main(outputDir: String) throws {
    try defineAST(
      outputDir: outputDir,
      baseName: "Expression",
      types: [
        // Using my own notation/form with `;` so that `:` can be only used for the typed properties
        "Binary   ; left: Expression, `operator`: Token, right: Expression",
        "Grouping ; expression: Expression",
        "Literal  ; value: String?",
        "Unary    ; `operator`: Token, right: Expression"
      ]
    )
  }

  private static func defineAST(
    outputDir: String,
    baseName: String,
    types: [String]
  ) throws {
    let fileURL = try AbsolutePath(validating: outputDir)
      .appending(component: "\(baseName).swift")

    if !FileManager.default.fileExists(atPath: fileURL.pathString) {
      FileManager.default.createFile(atPath: fileURL.pathString, contents: nil)
    }

    if let fileHandle = FileHandle(forWritingAtPath: fileURL.pathString) {
      try fileHandle.truncate(atOffset: 0) // clear before proceeding

      fileHandle.write("import Foundation\n\n".data(using: .utf8)!)
      fileHandle.write("indirect enum \(baseName): Equatable {\n".data(using: .utf8)!)

      fileHandle.write("  // The AST cases.\n".data(using: .utf8)!)

      struct ClassAndProperties: Equatable {
        let className: String
        let properties: [String]
      }

      let classes: [ClassAndProperties] = types.compactMap { type in
        let typeSplit = type.split(separator: ";")

        guard
          typeSplit.count == 2,
          let className = typeSplit.first.map(String.init),
          let propertiesString = typeSplit.last.map(String.init)
        else {
          return nil
        }
        
        let properties = propertiesString
          .split(separator: ",")
          .map(String.init)

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

      fileHandle.closeFile()
    }
  }

  private static func defineCase(
    fileHandle: FileHandle,
    baseName: String,
    className: String,
    fields: [String]
  ) {
    fileHandle.write(
      "  case \(className.lowercased())(\(className))\n"
        .data(using: .utf8)!
    )
  }

  private static func defineType(
    fileHandle: FileHandle,
    className: String,
    fields: [String]
  ) {
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
}
