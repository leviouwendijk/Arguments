import Foundation

public typealias ArgumentProgramErrorHandler = @Sendable (Error) async -> Int32

public enum ArgumentProgram {
    public static func main(
        arguments: [String] = Array(
            CommandLine.arguments.dropFirst()
        ),
        spec: @autoclosure @Sendable () throws -> CommandSpec,
        showsHelpForUnhandledCommand: Bool = true,
        @ArgumentApplicationBuilder _ build: @Sendable () -> [ArgumentApplicationComponent] = {
            []
        }
    ) async -> Never {
        let code = await run(
            arguments: arguments,
            spec: try spec(),
            showsHelpForUnhandledCommand: showsHelpForUnhandledCommand
        ) {
            build()
        }

        Foundation.exit(
            code
        )
    }

    public static func main(
        arguments: [String] = Array(
            CommandLine.arguments.dropFirst()
        ),
        spec: @autoclosure @Sendable () throws -> CommandSpec,
        showsHelpForUnhandledCommand: Bool = true,
        errorHandler: @escaping ArgumentProgramErrorHandler,
        @ArgumentApplicationBuilder _ build: @Sendable () -> [ArgumentApplicationComponent] = {
            []
        }
    ) async -> Never {
        let code = await run(
            arguments: arguments,
            spec: try spec(),
            showsHelpForUnhandledCommand: showsHelpForUnhandledCommand,
            errorHandler: errorHandler
        ) {
            build()
        }

        Foundation.exit(
            code
        )
    }

    public static func run(
        arguments: [String] = Array(
            CommandLine.arguments.dropFirst()
        ),
        spec: @autoclosure @Sendable () throws -> CommandSpec,
        showsHelpForUnhandledCommand: Bool = true,
        @ArgumentApplicationBuilder _ build: @Sendable () -> [ArgumentApplicationComponent] = {
            []
        }
    ) async -> Int32 {
        await runHandlingErrors(
            errorHandler: nil
        ) {
            let application = ArgumentApplication(
                spec: try spec(),
                showsHelpForUnhandledCommand: showsHelpForUnhandledCommand,
                build
            )

            try await application.run(
                arguments
            )
        }
    }

    public static func run(
        arguments: [String] = Array(
            CommandLine.arguments.dropFirst()
        ),
        spec: @autoclosure @Sendable () throws -> CommandSpec,
        showsHelpForUnhandledCommand: Bool = true,
        errorHandler: @escaping ArgumentProgramErrorHandler,
        @ArgumentApplicationBuilder _ build: @Sendable () -> [ArgumentApplicationComponent] = {
            []
        }
    ) async -> Int32 {
        await runHandlingErrors(
            errorHandler: errorHandler
        ) {
            let application = ArgumentApplication(
                spec: try spec(),
                showsHelpForUnhandledCommand: showsHelpForUnhandledCommand,
                build
            )

            try await application.run(
                arguments
            )
        }
    }

    public static func main<Root: ArgumentCommand>(
        arguments: [String] = Array(
            CommandLine.arguments.dropFirst()
        ),
        command root: Root.Type,
        showsHelpForUnhandledCommand: Bool = true,
        @ArgumentApplicationBuilder _ build: @Sendable () -> [ArgumentApplicationComponent] = {
            []
        }
    ) async -> Never {
        let code = await run(
            arguments: arguments,
            command: root,
            showsHelpForUnhandledCommand: showsHelpForUnhandledCommand
        ) {
            build()
        }

        Foundation.exit(
            code
        )
    }

    public static func main<Root: ArgumentCommand>(
        arguments: [String] = Array(
            CommandLine.arguments.dropFirst()
        ),
        command root: Root.Type,
        showsHelpForUnhandledCommand: Bool = true,
        errorHandler: @escaping ArgumentProgramErrorHandler,
        @ArgumentApplicationBuilder _ build: @Sendable () -> [ArgumentApplicationComponent] = {
            []
        }
    ) async -> Never {
        let code = await run(
            arguments: arguments,
            command: root,
            showsHelpForUnhandledCommand: showsHelpForUnhandledCommand,
            errorHandler: errorHandler
        ) {
            build()
        }

        Foundation.exit(
            code
        )
    }

    public static func run<Root: ArgumentCommand>(
        arguments: [String] = Array(
            CommandLine.arguments.dropFirst()
        ),
        command root: Root.Type,
        showsHelpForUnhandledCommand: Bool = true,
        @ArgumentApplicationBuilder _ build: @Sendable () -> [ArgumentApplicationComponent] = {
            []
        }
    ) async -> Int32 {
        await runHandlingErrors(
            errorHandler: nil
        ) {
            let application = ArgumentApplication(
                spec: try root.spec(),
                showsHelpForUnhandledCommand: showsHelpForUnhandledCommand,
                fallbackHandler: fallbackHandler(
                    for: root
                )
            ) {
                root.routes()
                build()
            }

            try await application.run(
                arguments
            )
        }
    }

    public static func run<Root: ArgumentCommand>(
        arguments: [String] = Array(
            CommandLine.arguments.dropFirst()
        ),
        command root: Root.Type,
        showsHelpForUnhandledCommand: Bool = true,
        errorHandler: @escaping ArgumentProgramErrorHandler,
        @ArgumentApplicationBuilder _ build: @Sendable () -> [ArgumentApplicationComponent] = {
            []
        }
    ) async -> Int32 {
        await runHandlingErrors(
            errorHandler: errorHandler
        ) {
            let application = ArgumentApplication(
                spec: try root.spec(),
                showsHelpForUnhandledCommand: showsHelpForUnhandledCommand,
                fallbackHandler: fallbackHandler(
                    for: root
                )
            ) {
                root.routes()
                build()
            }

            try await application.run(
                arguments
            )
        }
    }
}

private extension ArgumentProgram {
    static func fallbackHandler<Root: ArgumentCommand>(
        for root: Root.Type
    ) -> ArgumentCommandHandler? {
        guard let fallback = root as? any ArgumentCommandFallback.Type else {
            return nil
        }

        return { invocation in
            try await fallback.fallback(
                invocation
            )
        }
    }

    static func runHandlingErrors(
        errorHandler: ArgumentProgramErrorHandler?,
        operation: () async throws -> Void
    ) async -> Int32 {
        do {
            try await operation()

            return 0
        } catch {
            if let errorHandler {
                return await errorHandler(
                    error
                )
            }

            eprint(
                render(
                    error
                )
            )

            return 1
        }
    }

    static func render(
        _ error: Error
    ) -> String {
        (error as? LocalizedError)?.errorDescription
            ?? String(
                describing: error
            )
    }

    static func eprint(
        _ message: String
    ) {
        FileHandle.standardError.write(
            Data(
                (message + "\n").utf8
            )
        )
    }
}
