import Foundation

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
            showsHelpForUnhandledCommand: showsHelpForUnhandledCommand,
            build
        )

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
        do {
            let application = ArgumentApplication(
                spec: try spec(),
                showsHelpForUnhandledCommand: showsHelpForUnhandledCommand,
                build
            )

            try await application.run(
                arguments
            )

            return 0
        } catch {
            eprint(
                render(
                    error
                )
            )

            return 1
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
            showsHelpForUnhandledCommand: showsHelpForUnhandledCommand,
            build
        )

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
        let fallbackHandler: ArgumentCommandHandler? = {
            guard let fallback = Root.self as? any ArgumentCommandFallback.Type else {
                return nil
            }

            return { invocation in
                try await fallback.fallback(
                    invocation
                )
            }
        }()

        do {
            let application = ArgumentApplication(
                spec: try root.spec(),
                showsHelpForUnhandledCommand: showsHelpForUnhandledCommand,
                fallbackHandler: fallbackHandler
            ) {
                root.routes()
                build()
            }

            try await application.run(
                arguments
            )

            return 0
        } catch {
            eprint(
                render(
                    error
                )
            )

            return 1
        }
    }

    private static func render(
        _ error: Error
    ) -> String {
        (error as? LocalizedError)?.errorDescription
            ?? String(
                describing: error
            )
    }

    private static func eprint(
        _ message: String
    ) {
        FileHandle.standardError.write(
            Data(
                (message + "\n").utf8
            )
        )
    }
}
