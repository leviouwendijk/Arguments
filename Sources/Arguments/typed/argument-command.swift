public typealias ArgumentCommandType = any ArgumentCommand.Type

public protocol ArgumentCommand: Sendable {
    static var name: String { get }
    static var defaultChild: String? { get }
    static var children: [ArgumentCommandType] { get }

    static func components() throws -> [CommandComponentLowerable]
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
    static var defaultChild: String? {
        nil
    }

    static var children: [ArgumentCommandType] {
        []
    }

    static func components() throws -> [CommandComponentLowerable] {
        []
    }

    static func spec() throws -> CommandSpec {
        let child = defaultChild

        return try cmd(name) {
            if let child {
                DynamicMetadata(
                    .defaultChild(
                        CommandName(child)
                    )
                )
            }

            try components()

            try children.map {
                try cmd($0)
            }
        }
    }

    static func applicationComponents(
        below prefix: [String] = []
    ) -> [ArgumentApplicationComponent] {
        let path = prefix + [
            name,
        ]

        var components = children.flatMap {
            $0.applicationComponents(
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

    static func childApplicationComponents() -> [ArgumentApplicationComponent] {
        children.flatMap {
            $0.applicationComponents()
        }
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

public func commands(
    _ type: ArgumentCommandType
) -> [ArgumentApplicationComponent] {
    type.applicationComponents()
}

public func childCommands(
    _ type: ArgumentCommandType
) -> [ArgumentApplicationComponent] {
    type.childApplicationComponents()
}
