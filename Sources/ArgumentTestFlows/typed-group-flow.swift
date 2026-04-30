import Arguments
import TestFlows

extension ArgumentFlowSuite {
    static var typedGroupFlow: TestFlow {
        TestFlow(
            "typed-groups",
            tags: ["typed", "wrappers", "groups", "options"]
        ) {
            Step("@Group lowers nested fields into one param group") {
                let fixture = PeriodOptionsFixture()

                let params = try ArgumentFieldCollector.params(
                    of: fixture
                )

                try Expect.equal(
                    params.map { $0.name.rawValue },
                    [
                        "period",
                        "projection",
                    ],
                    "typed-groups.params.names"
                )

                guard case .group(let groupSpec) = params[1] else {
                    throw TestFlowAssertionFailure(
                        label: "typed-groups.group.case",
                        message: "second param was not a group",
                        actual: String(describing: params[1]),
                        expected: "group"
                    )
                }

                try Expect.equal(
                    groupSpec.params.map { $0.name.rawValue },
                    [
                        "taxonomy",
                        "presentation",
                        "projection-diagnostics",
                    ],
                    "typed-groups.inner.names"
                )
            }

            Step("parser sees params inside typed group") {
                let fixture = PeriodOptionsFixture()

                let spec = try cmd("period") {
                    params(
                        try ArgumentFieldCollector.params(
                            of: fixture
                        )
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "quarter",
                        "--taxonomy",
                        "rgs",
                        "--presentation",
                        "balance",
                        "income",
                        "--diag",
                    ],
                    command: spec
                )

                try Expect.equal(
                    try invocation.value(
                        "period",
                        as: String.self
                    ),
                    "quarter",
                    "typed-groups.parser.period"
                )

                try Expect.equal(
                    try invocation.value(
                        "taxonomy",
                        as: String.self
                    ),
                    "rgs",
                    "typed-groups.parser.taxonomy"
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
                    "typed-groups.parser.presentation"
                )

                try Expect.true(
                    try invocation.flag("projection-diagnostics"),
                    "typed-groups.parser.diag"
                )
            }

            Step("@Group binds nested option fields") {
                var fixture = PeriodOptionsFixture()

                let spec = try cmd("period") {
                    params(
                        try ArgumentFieldCollector.params(
                            of: fixture
                        )
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "year",
                        "--taxonomy",
                        "rgs",
                        "--presentation",
                        "balance",
                        "income",
                        "--diag",
                    ],
                    command: spec
                )

                try ArgumentFieldCollector.bind(
                    invocation,
                    into: &fixture
                )

                try Expect.equal(
                    fixture.period,
                    "year",
                    "typed-groups.binding.period"
                )

                try Expect.equal(
                    fixture.projection.taxonomy,
                    "rgs",
                    "typed-groups.binding.taxonomy"
                )

                try Expect.equal(
                    fixture.projection.presentation,
                    [
                        "balance",
                        "income",
                    ],
                    "typed-groups.binding.presentation"
                )

                try Expect.true(
                    fixture.projection.projectionDiagnostics,
                    "typed-groups.binding.diag"
                )
            }

            Step("@Group preserves nested defaults when missing") {
                var fixture = PeriodOptionsFixture()

                let spec = try cmd("period") {
                    params(
                        try ArgumentFieldCollector.params(
                            of: fixture
                        )
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [],
                    command: spec
                )

                try ArgumentFieldCollector.bind(
                    invocation,
                    into: &fixture
                )

                try Expect.equal(
                    fixture.period,
                    "month",
                    "typed-groups.defaults.period"
                )

                try Expect.isNil(
                    fixture.projection.taxonomy,
                    "typed-groups.defaults.taxonomy"
                )

                try Expect.equal(
                    fixture.projection.presentation,
                    [],
                    "typed-groups.defaults.presentation"
                )

                try Expect.false(
                    fixture.projection.projectionDiagnostics,
                    "typed-groups.defaults.diag"
                )
            }

            Step("@Opts supports repeating option occurrences") {
                var fixture = RepeatingOptionsFixture()

                let spec = try cmd("run") {
                    params(
                        try ArgumentFieldCollector.params(
                            of: fixture
                        )
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--stop",
                        ".",
                        "--stop",
                        "\\n",
                    ],
                    command: spec
                )

                try ArgumentFieldCollector.bind(
                    invocation,
                    into: &fixture
                )

                try Expect.equal(
                    fixture.stop,
                    [
                        ".",
                        "\\n",
                    ],
                    "typed-groups.opts.repeating"
                )
            }

            Step("duplicate names across typed group boundary throw") {
                try Expect.throwsError("typed-groups.duplicate-boundary") {
                    let fixture = PeriodOptionsFixture()

                    _ = try cmd("period") {
                        opt(
                            "taxonomy",
                            as: String.self
                        )

                        params(
                            try ArgumentFieldCollector.params(
                                of: fixture
                            )
                        )
                    }
                }
            }
        }
    }
}

private struct ProjectionOptionsFixture: ArgumentGroup {
    @Opt(
        "taxonomy",
        help: "Taxonomy profile to render through."
    )
    var taxonomy: String?

    @Opts(
        "presentation",
        take: .many,
        help: "Optional taxonomy presentation filters."
    )
    var presentation: [String]

    @Flag(
        "projection-diagnostics",
        alias: "diag",
        help: "Print taxonomy projection diagnostics."
    )
    var projectionDiagnostics: Bool

    init() {}
}

private struct PeriodOptionsFixture: Sendable {
    @Arg(
        "period",
        default: "month"
    )
    var period: String

    @Group("projection")
    var projection: ProjectionOptionsFixture

    init() {}
}

private struct RepeatingOptionsFixture: Sendable {
    @Opts(
        "stop",
        take: .repeating
    )
    var stop: [String]

    init() {}
}
