import Arguments
import TestFlows

extension ArgumentFlowSuite {
    static var typedBindingConvenienceFlow: TestFlow {
        TestFlow(
            "typed-binding-convenience",
            tags: [
                "typed",
                "wrappers",
                "binding",
                "ergonomics",
            ]
        ) {
            Step("params can be collected from a type") {
                let spec = try cmd("vat-status") {
                    try params(
                        VATStatusOptionsFixture.self
                    )
                }

                try Expect.equal(
                    spec.params.count,
                    1,
                    "typed-binding-convenience.params.count"
                )

                guard case .group(let group) = spec.params[0] else {
                    throw TestFlowAssertionFailure(
                        label: "typed-binding-convenience.params.group",
                        message: "expected params to lower through synthetic group",
                        actual: String(describing: spec.params[0]),
                        expected: "group"
                    )
                }

                try Expect.equal(
                    group.params.map(\.name.rawValue),
                    [
                        "period",
                        "anchor",
                        "trace",
                    ],
                    "typed-binding-convenience.params.names"
                )
            }

            Step("parsed invocation binds directly into typed options") {
                let spec = try cmd("vat-status") {
                    try params(
                        VATStatusOptionsFixture.self
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--anchor",
                        "2026Q1",
                        "--trace",
                        "quarter",
                    ],
                    command: spec
                )

                let options = try invocation.bind(
                    VATStatusOptionsFixture.self
                )

                try Expect.equal(
                    options.period,
                    "quarter",
                    "typed-binding-convenience.period"
                )

                try Expect.equal(
                    options.anchor,
                    "2026Q1",
                    "typed-binding-convenience.anchor"
                )

                try Expect.true(
                    options.trace,
                    "typed-binding-convenience.trace"
                )
            }
        }
    }
}

private struct VATStatusOptionsFixture: ArgumentGroup {
    @Arg(
        "period",
        default: "year"
    )
    var period: String

    @Opt("anchor")
    var anchor: String?

    @Flag("trace")
    var trace: Bool

    init() {}
}
