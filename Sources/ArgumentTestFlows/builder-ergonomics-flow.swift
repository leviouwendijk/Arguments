import Arguments
import TestFlows

extension ArgumentFlowSuite {
    static var builderErgonomicsFlow: TestFlow {
        TestFlow(
            "builder-ergonomics",
            tags: [
                "dsl",
                "builder",
                "conditionals",
                "ergonomics",
            ]
        ) {
            Step("command builder accepts conditional command branches") {
                let includeChat = true

                let spec = try cmd("agentic") {
                    try cmd("run") {
                        flag("json")
                    }

                    if includeChat {
                        try cmd("chat") {
                            flag("ephemeral")
                        }
                    }
                }

                try Expect.equal(
                    spec.children.map(\.name.rawValue),
                    [
                        "run",
                        "chat",
                    ],
                    "builder.command.conditional.children"
                )
            }

            Step("command builder accepts arrays from extracted helpers") {
                let extras: [CommandSpec] = [
                    try cmd("chat") {
                        flag("ephemeral")
                    },
                    try cmd("models") {
                        flag("json")
                    },
                ]

                let spec = try cmd("agentic") {
                    try cmd("run") {
                        flag("json")
                    }

                    extras
                }

                try Expect.equal(
                    spec.children.map(\.name.rawValue),
                    [
                        "run",
                        "chat",
                        "models",
                    ],
                    "builder.command.array.children"
                )
            }

            Step("param builder accepts conditional params") {
                let includeCustomRange = true
                let includeQuarter = true

                let spec = try cmd("period") {
                    try group("period-window") {
                        arg(
                            "period",
                            as: String.self,
                            default: "year"
                        )

                        flag("to-date")

                        if includeCustomRange {
                            opt(
                                "from",
                                as: String.self
                            )

                            opt(
                                "to",
                                as: String.self
                            )
                        }

                        if includeQuarter {
                            opt(
                                "quarter",
                                as: String.self
                            )
                        }
                    }
                }

                guard case .group(let group) = spec.params[0] else {
                    throw TestFlowAssertionFailure(
                        label: "builder.param.conditional.group",
                        message: "expected group param",
                        actual: String(describing: spec.params[0]),
                        expected: "group"
                    )
                }

                try Expect.equal(
                    group.params.map(\.name.rawValue),
                    [
                        "period",
                        "to-date",
                        "from",
                        "to",
                        "quarter",
                    ],
                    "builder.param.conditional.names"
                )
            }
        }
    }
}
