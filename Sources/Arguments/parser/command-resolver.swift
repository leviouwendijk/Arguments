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
        guard command.defaultChild != nil else {
            return false
        }

        guard rawValue.hasPrefix("-") else {
            return true
        }

        return !command.ownsOptionLikeToken(
            rawValue
        )
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

private extension CommandSpec {
    func ownsOptionLikeToken(
        _ rawValue: String
    ) -> Bool {
        if rawValue == "--" {
            return true
        }

        if rawValue.hasPrefix("--") {
            let name = String(
                rawValue
                    .dropFirst(2)
                    .split(separator: "=", maxSplits: 1)
                    .first ?? ""
            )

            return ownsLongOptionOrFlag(
                name
            )
        }

        if rawValue.hasPrefix("-"),
           rawValue.count >= 2 {
            let shortText = String(
                rawValue.dropFirst()
            )

            guard let first = shortText.first else {
                return false
            }

            return ownsShortOptionOrFlag(
                first
            )
        }

        return false
    }

    func ownsLongOptionOrFlag(
        _ name: String
    ) -> Bool {
        for param in params.flattenedParams {
            switch param {
            case .option(let option):
                if option.name.rawValue == name ||
                    option.aliases.contains(where: { $0.rawValue == name }) {
                    return true
                }

            case .flag(let flag):
                if flag.name.rawValue == name ||
                    flag.aliases.contains(where: { $0.rawValue == name }) {
                    return true
                }

            case .positional,
                 .group:
                continue
            }
        }

        return false
    }

    func ownsShortOptionOrFlag(
        _ short: Character
    ) -> Bool {
        for param in params.flattenedParams {
            switch param {
            case .option(let option):
                if option.short == short {
                    return true
                }

            case .flag(let flag):
                if flag.short == short {
                    return true
                }

            case .positional,
                 .group:
                continue
            }
        }

        return false
    }
}
