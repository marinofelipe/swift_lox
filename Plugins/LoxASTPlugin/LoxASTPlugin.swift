//
//  LoxASTPlugin.swift
//
//
//  Created by Marino Felipe on 01.04.24.
//

import Foundation
import PackagePlugin

@main
struct LoxASTPlugin: BuildToolPlugin {
  func createBuildCommands(
    context: PluginContext,
    target: Target
  ) async throws -> [Command] {
    [
      .buildCommand(
        displayName: "Lox AST Generator",
        executable: try context.tool(named: "LoxAST").path,
        arguments: [
          "--output-dir",
          context.pluginWorkDirectory
        ],
        outputFiles: [
          context.pluginWorkDirectory.appending("Expression.swift")
        ]
      )
    ]
  }
}
