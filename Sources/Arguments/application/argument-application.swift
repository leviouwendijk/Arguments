public typealias ArgumentCommandHandler = @Sendable (ParsedInvocation) async throws -> Void

public struct ArgumentApplication: Sendable {
    public var spec: CommandSpec
    public var showsHelpForUnhandledCommand: Bool

    private var routes: [ArgumentRoute]
    private var defaultHandler: ArgumentCommandHandler?

    public init(
        spec: CommandSpec,
        showsHelpForUnhandledCommand: Bool = true,
        @ArgumentApplicationBuilder _ build: () -> [ArgumentApplicationComponent]
    ) {
        self.spec = spec
        self.showsHelpForUnhandledCommand = showsHelpForUnhandledCommand
        self.routes = []
        self.defaultHandler = nil

        for component in build() {
            switch component {
            case .route(let route):
                routes.append(
                    route
                )

            case .defaultCommand(let handler):
                defaultHandler = handler
            }
        }
    }

    public func run(
        _ arguments: [String] = Array(CommandLine.arguments.dropFirst())
    ) async throws {
        if try renderHelpIfRequested(
            arguments
        ) {
            return
        }

        let invocation = try Arguments.parse(
            arguments,
            spec: spec
        )

        let relativePath = relativeCommandPath(
            for: invocation
        )

        if relativePath.isEmpty,
           let defaultHandler {
            try await defaultHandler(
                invocation
            )
            return
        }

        if let route = routes.first(where: { $0.path == relativePath }) {
            try await route.run(
                invocation
            )
            return
        }

        if showsHelpForUnhandledCommand {
            print(
                ArgumentHelpRenderer().render(
                    command: spec
                )
            )
            return
        }

        throw ArgumentApplicationError.unhandled_command(
            invocation.commandPath.map(\.rawValue)
        )
    }
}

private extension ArgumentApplication {
    func relativeCommandPath(
        for invocation: ParsedInvocation
    ) -> [String] {
        var path = invocation.commandPath.map(\.rawValue)

        if path.first == spec.name.rawValue {
            path.removeFirst()
        }

        return path
    }

    func renderHelpIfRequested(
        _ arguments: [String]
    ) throws -> Bool {
        guard arguments.contains("--help") || arguments.contains("-h") else {
            return false
        }

        let helpArguments = arguments.filter {
            $0 != "--help" && $0 != "-h"
        }

        let resolution = try? CommandResolver.resolve(
            helpArguments,
            root: spec
        )

        if let resolution {
            let parentPath = Array(
                resolution.path.dropLast()
            )

            print(
                ArgumentHelpRenderer().render(
                    command: resolution.command,
                    path: parentPath
                )
            )
        } else {
            print(
                ArgumentHelpRenderer().render(
                    command: spec
                )
            )
        }

        return true
    }
}
