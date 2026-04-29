public struct ArgumentRoute: Sendable {
    public var path: [String]

    private let handler: ArgumentCommandHandler

    public init(
        path: [String],
        handler: @escaping ArgumentCommandHandler
    ) {
        self.path = path
        self.handler = handler
    }

    public func run(
        _ invocation: ParsedInvocation
    ) async throws {
        try await handler(
            invocation
        )
    }
}

public enum ArgumentApplicationComponent: Sendable {
    case route(ArgumentRoute)
    case defaultCommand(ArgumentCommandHandler)
}

@resultBuilder
public enum ArgumentApplicationBuilder {
    public static func buildBlock(
        _ components: ArgumentApplicationComponent...
    ) -> [ArgumentApplicationComponent] {
        components
    }

    public static func buildArray(
        _ components: [[ArgumentApplicationComponent]]
    ) -> [ArgumentApplicationComponent] {
        components.flatMap {
            $0
        }
    }

    public static func buildOptional(
        _ components: [ArgumentApplicationComponent]?
    ) -> [ArgumentApplicationComponent] {
        components ?? []
    }

    public static func buildEither(
        first components: [ArgumentApplicationComponent]
    ) -> [ArgumentApplicationComponent] {
        components
    }

    public static func buildEither(
        second components: [ArgumentApplicationComponent]
    ) -> [ArgumentApplicationComponent] {
        components
    }
}
