import Arguments
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
