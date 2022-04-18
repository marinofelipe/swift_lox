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
        help: """
            A relative or absolute file path that contains lox code to be executed
            """
    )
    var filePath: URL?

    public init() {}

    public func run() throws {
        var args = [String]()
        if let filePath = filePath {
            args.append(filePath.path)
        }

        try Lox.main(args: args)
    }
}

extension URL: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(string: argument)
    }
}
