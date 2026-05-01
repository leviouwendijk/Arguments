public typealias ArgumentCommandType = any ArgumentCommand.Type

public protocol ArgumentCommand: Sendable {
    associatedtype DefaultChild: ArgumentCommand = NoDefaultArgumentCommand

    static var name: String { get }
    static var aliases: [String] { get }
    static var defaultChild: DefaultChild.Type { get }
    static var children: [ArgumentCommandType] { get }

    static func components() throws -> [CommandComponentLowerable]
}

public enum NoDefaultArgumentCommand: ArgumentCommand {
    public static let name = "__arguments_no_default_child"
}

public protocol ArgumentCommandFallback: ArgumentCommand {
    static func fallback(
        _ invocation: ParsedInvocation
    ) async throws
}

public protocol RunnableArgumentCommand: ArgumentCommand {
    static func run(
        _ invocation: ParsedInvocation
    ) async throws
}

public protocol BoundArgumentCommand: RunnableArgumentCommand {
    associatedtype Options: ArgumentGroup

    static func run(
        _ options: Options,
        invocation: ParsedInvocation
    ) async throws
}

public protocol ParsedArgumentCommand: RunnableArgumentCommand {
    associatedtype Options: ArgumentParsed

    static func run(
        _ options: Options,
        invocation: ParsedInvocation
    ) async throws
}

public extension ArgumentCommand {
    static var aliases: [String] {
        []
    }

    static var children: [ArgumentCommandType] {
        []
    }

    static func components() throws -> [CommandComponentLowerable] {
        []
    }

    static func spec() throws -> CommandSpec {
        let defaultChild = resolvedDefaultChild()

        return try cmd(name) {
            for alias in aliases {
                DynamicMetadata(
                    .alias(
                        CommandAlias(alias)
                    )
                )
            }

            if let defaultChild {
                DynamicMetadata(
                    .defaultChild(
                        CommandName(defaultChild.name)
                    )
                )
            }

            try components()

            try children.map {
                try cmd($0)
            }
        }
    }

    private static func resolvedDefaultChild() -> ArgumentCommandType? {
        guard DefaultChild.self != NoDefaultArgumentCommand.self else {
            return nil
        }

        return defaultChild
    }
}

public extension ArgumentCommand
where DefaultChild == NoDefaultArgumentCommand {
    static var defaultChild: NoDefaultArgumentCommand.Type {
        NoDefaultArgumentCommand.self
    }
}

extension ArgumentCommand {
    static func routes() -> [ArgumentApplicationComponent] {
        children.flatMap {
            $0.routeComponents()
        }
    }

    static func routeComponents(
        below prefix: [String] = []
    ) -> [ArgumentApplicationComponent] {
        let path = prefix + [
            name,
        ]

        var components = children.flatMap {
            $0.routeComponents(
                below: path
            )
        }

        if let runnable = Self.self as? any RunnableArgumentCommand.Type {
            components.append(
                command(
                    path,
                    use: { invocation in
                        try await runnable.run(
                            invocation
                        )
                    }
                )
            )
        }

        return components
    }
}

public extension BoundArgumentCommand {
    static func components() throws -> [CommandComponentLowerable] {
        [
            try params(
                Options.self
            ),
        ]
    }

    static func run(
        _ invocation: ParsedInvocation
    ) async throws {
        try await run(
            invocation.bind(
                Options.self
            ),
            invocation: invocation
        )
    }
}

public extension ParsedArgumentCommand {
    static func components() throws -> [CommandComponentLowerable] {
        [
            try params(
                Options.self
            ),
        ]
    }

    static func run(
        _ invocation: ParsedInvocation
    ) async throws {
        try await run(
            invocation.parse(
                Options.self
            ),
            invocation: invocation
        )
    }
}

public func cmd(
    _ type: ArgumentCommandType
) throws -> CommandSpec {
    try type.spec()
}

public extension ArgumentCommand {
    static func main() async {
        await ArgumentProgram.main(
            command: Self.self
        )
    }

    static func main(
        errorHandler: @escaping ArgumentProgramErrorHandler
    ) async {
        await ArgumentProgram.main(
            command: Self.self,
            errorHandler: errorHandler
        )
    }

    static func run(
        arguments: [String] = Array(
            CommandLine.arguments.dropFirst()
        )
    ) async -> Int32 {
        await ArgumentProgram.run(
            arguments: arguments,
            command: Self.self
        )
    }

    static func run(
        arguments: [String] = Array(
            CommandLine.arguments.dropFirst()
        ),
        errorHandler: @escaping ArgumentProgramErrorHandler
    ) async -> Int32 {
        await ArgumentProgram.run(
            arguments: arguments,
            command: Self.self,
            errorHandler: errorHandler
        )
    }
}
