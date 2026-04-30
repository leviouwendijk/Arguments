public struct CommandResolution: Sendable {
    public var root: CommandSpec
    public var command: CommandSpec
    public var path: [CommandName]
    public var remainingArgv: [String]

    public init(
        root: CommandSpec,
        command: CommandSpec,
        path: [CommandName],
        remainingArgv: [String]
    ) {
        self.root = root
        self.command = command
        self.path = path
        self.remainingArgv = remainingArgv
    }
}

public enum CommandResolver {
    public static func resolve(
        _ argv: [String],
        root: CommandSpec
    ) throws -> CommandResolution {
        var cursor = ArgvCursor(argv)
        var command = root
        var path: [CommandName] = [
            root.name
        ]

        if let current = cursor.peek(),
           matches(current, command: root) {
            cursor.advance()
        }

        while true {
            guard let current = cursor.peek() else {
                guard command.defaultChild != nil else {
                    break
                }

                let child = try defaultChild(
                    of: command
                )

                command = child

                path.append(
                    child.name
                )

                continue
            }

            if let child = command.children.first(where: { matches(current, command: $0) }) {
                command = child

                path.append(
                    child.name
                )

                cursor.advance()

                continue
            }

            if shouldUseDefaultChild(
                current,
                command: command
            ) {
                let child = try defaultChild(
                    of: command
                )

                command = child

                path.append(
                    child.name
                )

                continue
            }

            if shouldTreatAsUnknownChildCommand(
                current,
                command: command
            ) {
                throw ArgumentParseError.unknown_command(
                    current
                )
            }

            break
        }

        return CommandResolution(
            root: root,
            command: command,
            path: path,
            remainingArgv: Array(
                argv[cursor.index..<argv.endIndex]
            )
        )
    }

    private static func shouldUseDefaultChild(
        _ rawValue: String,
        command: CommandSpec
    ) -> Bool {
        command.defaultChild != nil
            && !rawValue.hasPrefix("-")
    }

    private static func defaultChild(
        of command: CommandSpec
    ) throws -> CommandSpec {
        guard let name = command.defaultChild else {
            throw ArgumentParseError.missing_default_child(
                CommandName("")
            )
        }

        guard let child = command.children.first(where: { $0.name == name }) else {
            throw ArgumentParseError.missing_default_child(
                name
            )
        }

        return child
    }

    private static func shouldTreatAsUnknownChildCommand(
        _ rawValue: String,
        command: CommandSpec
    ) -> Bool {
        !command.children.isEmpty
            && !rawValue.hasPrefix("-")
    }

    private static func matches(
        _ rawValue: String,
        command: CommandSpec
    ) -> Bool {
        command.name.rawValue == rawValue
            || command.aliases.contains {
                $0.rawValue == rawValue
            }
    }
}
