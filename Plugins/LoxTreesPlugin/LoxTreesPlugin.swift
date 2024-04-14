//
//  LoxTreesPlugin.swift
//
//
//  Created by Marino Felipe on 01.04.24.
//

import Foundation
import PackagePlugin

@main
struct LoxTreesPlugin: BuildToolPlugin {
  func createBuildCommands(
    context: PluginContext,
    target: Target
  ) async throws -> [Command] {
    [
      .buildCommand(
        displayName: "Lox AST Generator",
        executable: try context.tool(named: "LoxTrees").path,
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
