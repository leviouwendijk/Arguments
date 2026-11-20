import Arguments
import Testing

extension ArgumentTestSuite {
    static var argumentCommandAliasFlow: TestSuite {
        TestSuite(
            "argument-command-aliases",
            tags: [
                "typed",
                "commands",
                "aliases",
                "parser",
            ]
        ) {
            Test("typed command aliases lower into command specs") {
                let spec = try AliasRootCommandFixture.spec()

                try Expect.equal(
                    spec.aliases.map(\.rawValue),
                    [
                        "a",
                    ],
                    "argument-command-alias.root"
                )

                try Expect.equal(
                    spec.children[0].aliases.map(\.rawValue),
                    [
                        "r",
                        "execute",
                    ],
                    "argument-command-alias.child"
                )
            }

            Test("typed command aliases resolve to canonical command path") {
                let invocation = try Arguments.parse(
                    [
                        "a",
                        "r",
                        "--json",
                    ],
                    spec: try AliasRootCommandFixture.spec()
                )

                try Expect.equal(
                    invocation.commandPath.map(\.rawValue),
                    [
                        "agentic",
                        "run",
                    ],
                    "argument-command-alias.path"
                )

                try Expect.true(
                    try invocation.flag("json"),
                    "argument-command-alias.flag"
                )
            }

            Test("command aliases render in help") {
                let help = ArgumentHelpRenderer().render(
                    command: try AliasRootCommandFixture.spec()
                )

                try Expect.contains(
                    help,
                    "run, r, execute",
                    "argument-command-alias.help"
                )
            }

            Test("duplicate command alias across siblings throws") {
                try Expect.throwsError(
                    "argument-command-alias.duplicate"
                ) {
                    _ = try cmd("agentic") {
                        try cmd("run") {
                            alias("r")
                        }

                        try cmd("render") {
                            alias("r")
                        }
                    }
                }
            }
        }
    }
}

private enum AliasRootCommandFixture: ArgumentCommand {
    static let name = "agentic"
    static let aliases = [
        "a",
    ]

    static var children: [ArgumentCommandType] {
        [
            AliasRunCommandFixture.self,
        ]
    }
}

private enum AliasRunCommandFixture: RunnableArgumentCommand {
    static let name = "run"
    static let aliases = [
        "r",
        "execute",
    ]

    static func components() throws -> [CommandComponentLowerable] {
        [
            flag("json"),
        ]
    }

    static func run(
        _ invocation: ParsedInvocation
    ) async throws {}
}
