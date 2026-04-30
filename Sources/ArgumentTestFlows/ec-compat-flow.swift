import Foundation
import Arguments
import TestFlows

extension ArgumentFlowSuite {
    static var paramAliasFlow: TestFlow {
        TestFlow(
            "param-aliases",
            tags: ["argv", "parser", "aliases"]
        ) {
            Step("long alias writes canonical flag") {
                let spec = try cmd("run") {
                    flag(
                        "projection-diagnostics",
                        alias: "diag"
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--diag",
                    ],
                    command: spec
                )

                try Expect.true(
                    try invocation.flag("projection-diagnostics"),
                    "param-alias.flag.canonical"
                )
            }

            Step("long alias writes canonical option") {
                let spec = try cmd("run") {
                    opt(
                        "project",
                        alias: "root",
                        as: String.self
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--root",
                        "/tmp/project",
                    ],
                    command: spec
                )

                try Expect.equal(
                    try invocation.value(
                        "project",
                        as: String.self
                    ),
                    "/tmp/project",
                    "param-alias.option.canonical"
                )
            }

            Step("duplicate alias across params throws") {
                try Expect.throwsError("param-alias.duplicate") {
                    _ = try cmd("run") {
                        flag("diag")

                        flag(
                            "projection-diagnostics",
                            alias: "diag"
                        )
                    }
                }
            }

            Step("help renders canonical and alias") {
                let spec = try cmd("run") {
                    flag(
                        "projection-diagnostics",
                        alias: "diag",
                        help: "Print diagnostics."
                    )
                }

                let help = ArgumentHelpRenderer().render(
                    command: spec
                )

                try Expect.contains(
                    help,
                    "--projection-diagnostics, --diag",
                    "param-alias.help"
                )
            }
        }
    }

    static var manyOptionFlow: TestFlow {
        TestFlow(
            "many-options",
            tags: ["argv", "parser", "options"]
        ) {
            Step("many option consumes until next option") {
                let spec = try cmd("run") {
                    opt(
                        "presentation",
                        as: String.self,
                        take: .many
                    )

                    flag("diag")
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--presentation",
                        "balance",
                        "income",
                        "--diag",
                    ],
                    command: spec
                )

                try Expect.equal(
                    try invocation.values(
                        "presentation",
                        as: String.self
                    ),
                    [
                        "balance",
                        "income",
                    ],
                    "many-options.values"
                )

                try Expect.true(
                    try invocation.flag("diag"),
                    "many-options.next-flag"
                )
            }

            Step("many option supports repeated occurrences") {
                let spec = try cmd("run") {
                    opt(
                        "presentation",
                        as: String.self,
                        take: .many
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--presentation",
                        "balance",
                        "--presentation",
                        "income",
                    ],
                    command: spec
                )

                try Expect.equal(
                    try invocation.values(
                        "presentation",
                        as: String.self
                    ),
                    [
                        "balance",
                        "income",
                    ],
                    "many-options.repeated"
                )
            }

            Step("many option supports equals values") {
                let spec = try cmd("run") {
                    opt(
                        "presentation",
                        as: String.self,
                        take: .many
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--presentation=balance",
                        "--presentation=income",
                    ],
                    command: spec
                )

                try Expect.equal(
                    try invocation.values(
                        "presentation",
                        as: String.self
                    ),
                    [
                        "balance",
                        "income",
                    ],
                    "many-options.equals"
                )
            }

            Step("many option respects terminator") {
                let spec = try cmd("run") {
                    opt(
                        "presentation",
                        as: String.self,
                        take: .many
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--presentation",
                        "balance",
                        "--",
                        "--literal",
                    ],
                    command: spec
                )

                try Expect.equal(
                    try invocation.values(
                        "presentation",
                        as: String.self
                    ),
                    [
                        "balance",
                    ],
                    "many-options.terminator.values"
                )

                try Expect.equal(
                    invocation.passthrough,
                    [
                        "--literal",
                    ],
                    "many-options.terminator.passthrough"
                )
            }
        }
    }

    static var defaultValueFlow: TestFlow {
        TestFlow(
            "default-values",
            tags: ["argv", "parser", "defaults"]
        ) {
            Step("missing option uses default") {
                let spec = try cmd("run") {
                    opt(
                        "margins",
                        as: Double.self,
                        default: 40.0
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [],
                    command: spec
                )

                try Expect.equal(
                    try invocation.value(
                        "margins",
                        as: Double.self
                    ),
                    40.0,
                    "default-values.option.missing"
                )
            }

            Step("provided option overrides default") {
                let spec = try cmd("run") {
                    opt(
                        "margins",
                        as: Double.self,
                        default: 40.0
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--margins",
                        "28.5",
                    ],
                    command: spec
                )

                try Expect.equal(
                    try invocation.value(
                        "margins",
                        as: Double.self
                    ),
                    28.5,
                    "default-values.option.override"
                )
            }

            Step("missing positional uses default") {
                let spec = try cmd("run") {
                    arg(
                        "period",
                        as: String.self,
                        default: "quarter"
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [],
                    command: spec
                )

                try Expect.equal(
                    try invocation.value(
                        "period",
                        as: String.self
                    ),
                    "quarter",
                    "default-values.positional.missing"
                )
            }
        }
    }

    static var decimalValueFlow: TestFlow {
        TestFlow(
            "decimal-values",
            tags: ["argv", "parser", "values"]
        ) {
            Step("decimal parser accepts POSIX decimal") {
                try Expect.equal(
                    try Decimal.parser.parse("0.01"),
                    Decimal(string: "0.01", locale: Locale(identifier: "en_US_POSIX"))!,
                    "decimal-values.posix"
                )
            }

            Step("decimal parser rejects invalid values") {
                try Expect.throwsError("decimal-values.invalid") {
                    _ = try Decimal.parser.parse("nope")
                }
            }
        }
    }

    static var ecCompatibilityFlow: TestFlow {
        TestFlow(
            "ec-compatibility",
            tags: ["argv", "parser", "ec"]
        ) {
            Step("parse vat overview shape") {
                let invocation = try Arguments.parse(
                    [
                        "ec",
                        "vat",
                        "overview",
                        "quarter",
                        "--anchor",
                        "2026Q1",
                        "--pdf",
                    ],
                    spec: try ecFixtureSpec()
                )

                try Expect.equal(
                    invocation.commandPath.map(\.rawValue),
                    [
                        "ec",
                        "vat",
                        "overview",
                    ],
                    "ec-compatibility.vat.path"
                )

                try Expect.equal(
                    try invocation.value(
                        "period",
                        as: String.self
                    ),
                    "quarter",
                    "ec-compatibility.vat.period"
                )

                try Expect.equal(
                    try invocation.value(
                        "anchor",
                        as: String.self
                    ),
                    "2026Q1",
                    "ec-compatibility.vat.anchor"
                )

                try Expect.true(
                    try invocation.flag("pdf"),
                    "ec-compatibility.vat.pdf"
                )
            }

            Step("parse period presentation and diag alias") {
                let invocation = try Arguments.parse(
                    [
                        "ec",
                        "period",
                        "--presentation",
                        "balance",
                        "income",
                        "--diag",
                    ],
                    spec: try ecFixtureSpec()
                )

                try Expect.equal(
                    try invocation.values(
                        "presentation",
                        as: String.self
                    ),
                    [
                        "balance",
                        "income",
                    ],
                    "ec-compatibility.period.presentation"
                )

                try Expect.true(
                    try invocation.flag("projection-diagnostics"),
                    "ec-compatibility.period.diag"
                )
            }

            Step("parse source render filters") {
                let invocation = try Arguments.parse(
                    [
                        "ec",
                        "source",
                        "render",
                        "entries",
                        "--id",
                        "1",
                        "2",
                        "--group",
                        "tax",
                        "--path",
                        "entries/2026",
                    ],
                    spec: try ecFixtureSpec()
                )

                try Expect.equal(
                    try invocation.value(
                        "scope",
                        as: String.self
                    ),
                    "entries",
                    "ec-compatibility.source.scope"
                )

                try Expect.equal(
                    try invocation.values(
                        "id",
                        as: String.self
                    ),
                    [
                        "1",
                        "2",
                    ],
                    "ec-compatibility.source.id"
                )

                try Expect.equal(
                    try invocation.values(
                        "group",
                        as: String.self
                    ),
                    [
                        "tax",
                    ],
                    "ec-compatibility.source.group"
                )

                try Expect.equal(
                    try invocation.values(
                        "path",
                        as: String.self
                    ),
                    [
                        "entries/2026",
                    ],
                    "ec-compatibility.source.path"
                )
            }
        }
    }
}

private func ecFixtureSpec() throws -> CommandSpec {
    try cmd("ec") {
        defaultChild("compile")

        try cmd("compile") {
            flag("verbose", short: "v")
        }

        try cmd("vat") {
            defaultChild("overview")

            try cmd("overview") {
                arg(
                    "period",
                    as: String.self,
                    default: "quarter"
                )

                opt(
                    "project",
                    short: "p",
                    as: String.self
                )

                opt("anchor", as: String.self)
                opt("from", as: String.self)
                opt("to", as: String.self)

                opt(
                    "margins",
                    as: Double.self,
                    default: 40.0
                )

                flag("pdf")
                flag("trace")
            }

            try cmd("status") {
                arg(
                    "period",
                    as: String.self,
                    default: "quarter"
                )

                opt("anchor", as: String.self)
                flag("show-entries")
            }
        }

        try cmd("period") {
            opt(
                "presentation",
                as: String.self,
                take: .many
            )

            flag(
                "projection-diagnostics",
                alias: "diag"
            )
        }

        try cmd("source") {
            try cmd("render") {
                arg(
                    "scope",
                    as: String.self,
                    default: "entries"
                )

                opt(
                    "id",
                    as: String.self,
                    take: .many
                )

                opt(
                    "group",
                    as: String.self,
                    take: .many
                )

                opt(
                    "path",
                    as: String.self,
                    take: .many
                )
            }
        }
    }
}
