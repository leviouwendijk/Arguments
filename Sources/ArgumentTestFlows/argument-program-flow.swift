import Arguments
import Foundation
import TestFlows

extension ArgumentFlowSuite {
    static var argumentProgramFlow: TestFlow {
        TestFlow(
            "argument-program",
            tags: [
                "application",
                "program",
                "main",
                "ergonomics",
            ]
        ) {
            Step("program wrapper runs routed command") {
                let spec = try cmd("agentic") {
                    try cmd("run") {
                        arg(
                            "prompt",
                            as: String.self
                        )
                    }
                }

                final class Box: @unchecked Sendable {
                    var prompt = ""
                }

                let box = Box()

                let code = await ArgumentProgram.run(
                    arguments: [
                        "run",
                        "hello",
                    ],
                    spec: spec
                ) {
                    command("run") { invocation in
                        box.prompt = try invocation.value(
                            "prompt",
                            as: String.self
                        ) ?? ""
                    }
                }

                try Expect.equal(
                    code,
                    0,
                    "argument-program.code"
                )

                try Expect.equal(
                    box.prompt,
                    "hello",
                    "argument-program.prompt"
                )
            }

            Step("program wrapper catches route errors") {
                let spec = try cmd("agentic") {
                    try cmd("run") {
                        flag("json")
                    }
                }

                let code = await ArgumentProgram.run(
                    arguments: [
                        "run",
                    ],
                    spec: spec
                ) {
                    command("run") { _ in
                        throw ArgumentApplicationError.unhandled_command(
                            [
                                "run",
                            ]
                        )
                    }
                }

                try Expect.equal(
                    code,
                    1,
                    "argument-program.error-code"
                )
            }

            Step("program wrapper can use custom error handler") {
                let spec = try cmd("agentic") {
                    try cmd("run") {
                        flag("json")
                    }
                }

                final class Box: @unchecked Sendable {
                    var message = ""
                }

                let box = Box()

                let code = await ArgumentProgram.run(
                    arguments: [
                        "run",
                    ],
                    spec: spec,
                    errorHandler: { error in
                        box.message = (error as? LocalizedError)?.errorDescription
                            ?? String(
                                describing: error
                            )

                        return 7
                    }
                ) {
                    command("run") { _ in
                        throw ArgumentApplicationError.unhandled_command(
                            [
                                "run",
                            ]
                        )
                    }
                }

                try Expect.equal(
                    code,
                    7,
                    "argument-program.custom-error-code"
                )

                try Expect.equal(
                    box.message,
                    "Unhandled command 'run'.",
                    "argument-program.custom-error-message"
                )
            }

            Step("typed program wrapper can use custom error handler") {
                final class Box: @unchecked Sendable {
                    var message = ""
                }

                let box = Box()

                let code = await ArgumentProgram.run(
                    arguments: [
                        "fail",
                    ],
                    command: CustomErrorRootFixture.self,
                    errorHandler: { error in
                        box.message = (error as? LocalizedError)?.errorDescription
                            ?? String(
                                describing: error
                            )

                        return 9
                    }
                )

                try Expect.equal(
                    code,
                    9,
                    "argument-program.typed-custom-error-code"
                )

                try Expect.equal(
                    box.message,
                    "fixture failed",
                    "argument-program.typed-custom-error-message"
                )
            }

            Step("program route builder accepts conditional routes") {
                let spec = try cmd("agentic") {
                    try cmd("run") {
                        flag("json")
                    }

                    try cmd("chat") {
                        flag("ephemeral")
                    }
                }

                let includeChat = true

                final class Box: @unchecked Sendable {
                    var command = ""
                }

                let box = Box()

                let code = await ArgumentProgram.run(
                    arguments: [
                        "chat",
                    ],
                    spec: spec
                ) {
                    command("run") { _ in
                        box.command = "run"
                    }

                    if includeChat {
                        command("chat") { _ in
                            box.command = "chat"
                        }
                    }
                }

                try Expect.equal(
                    code,
                    0,
                    "argument-program.conditional.code"
                )

                try Expect.equal(
                    box.command,
                    "chat",
                    "argument-program.conditional.command"
                )
            }
        }
    }
}

private enum CustomErrorRootFixture: ArgumentCommand {
    static let name = "agentic"

    static let children: [ArgumentCommandType] = [
        CustomErrorFailFixture.self,
    ]
}

private enum CustomErrorFailFixture: RunnableArgumentCommand {
    static let name = "fail"

    static func run(
        _ invocation: ParsedInvocation
    ) async throws {
        throw CustomErrorFixtureError()
    }
}

private struct CustomErrorFixtureError: Error, LocalizedError {
    var errorDescription: String? {
        "fixture failed"
    }
}
