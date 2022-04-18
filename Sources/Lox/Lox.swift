import Foundation

public enum Lox {
    public static func main(args: [String]) throws {
        if args.count > 1 {
            print("Usage: swift_lox [script]")
            exit(64)
        } else if (args.count == 1) {
            try runFile(path: args[0])
        } else {
            try runPrompt()
        }
    }

    private static func runFile(path: String) throws {
        let fileContents = try String(contentsOfFile: path, encoding: .utf8)
        run(source: fileContents)
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
                "\(ANSIColor.boldPurple.rawValue)>\(ANSIColor.default.rawValue)",
                terminator: ""
            )

            guard inputLine.isEmpty == false else {
                break
            }

            run(source: inputLine)
        }
    }

    private static func run(source: String) {
        let dumbTokens = source.split(separator: " ")

        // For now, just print the tokens.
        for token in dumbTokens {
            print(token)
        }
    }
}
