import Arguments
import Foundation
import TestFlows

extension ArgumentFlowSuite {
    static var argumentParsedFlow: TestFlow {
        TestFlow(
            "argument-parsed",
            tags: [
                "typed",
                "payload",
                "parse",
                "context",
                "dsl",
            ]
        ) {
            Step("params can be collected from parsed type payload") {
                let spec = try parsedFixtureSpec()

                guard case .group(let group) = spec.params[0] else {
                    throw TestFlowAssertionFailure(
                        label: "argument-parsed.params.group",
                        message: "expected params to lower through synthetic group",
                        actual: String(describing: spec.params[0]),
                        expected: "group"
                    )
                }

                try Expect.equal(
                    group.params.map(\.name.rawValue),
                    [
                        "name",
                        "count",
                    ],
                    "argument-parsed.params.names"
                )
            }

            Step("parse returns strong type from loose payload") {
                let invocation = try ArgumentParser.parse(
                    [
                        "--name",
                        "  levi  ",
                        "--count",
                        "3",
                    ],
                    command: try parsedFixtureSpec()
                )

                let parsed = try invocation.parse(
                    ParsedOptionsFixture.self
                )

                try Expect.equal(
                    parsed.name.rawValue,
                    "levi",
                    "argument-parsed.name"
                )

                try Expect.equal(
                    parsed.count,
                    3,
                    "argument-parsed.count"
                )
            }

            Step("parse rejects invalid semantic payload") {
                let invocation = try ArgumentParser.parse(
                    [
                        "--name",
                        "   ",
                    ],
                    command: try parsedFixtureSpec()
                )

                try Expect.throwsError(
                    "argument-parsed.invalid-name"
                ) {
                    _ = try invocation.parse(
                        ParsedOptionsFixture.self
                    )
                }
            }

            Step("context parse receives runtime context") {
                let invocation = try ArgumentParser.parse(
                    [
                        "--count",
                        "4",
                    ],
                    command: try contextParsedFixtureSpec()
                )

                let parsed = try invocation.parse(
                    ContextParsedOptionsFixture.self,
                    in: ParsedContextFixture(
                        defaultName: "context-name",
                        multiplier: 2
                    )
                )

                try Expect.equal(
                    parsed.name.rawValue,
                    "context-name",
                    "argument-parsed.context.name"
                )

                try Expect.equal(
                    parsed.count,
                    8,
                    "argument-parsed.context.count"
                )
            }

            Step("context parse rejects invalid context result") {
                let invocation = try ArgumentParser.parse(
                    [],
                    command: try contextParsedFixtureSpec()
                )

                try Expect.throwsError(
                    "argument-parsed.context.invalid"
                ) {
                    _ = try invocation.parse(
                        ContextParsedOptionsFixture.self,
                        in: ParsedContextFixture(
                            defaultName: "   ",
                            multiplier: 1
                        )
                    )
                }
            }
        }
    }
}

private func parsedFixtureSpec() throws -> CommandSpec {
    try cmd("parsed") {
        try params(
            ParsedOptionsFixture.self
        )
    }
}

private func contextParsedFixtureSpec() throws -> CommandSpec {
    try cmd("parsed-context") {
        try params(
            ContextParsedOptionsFixture.self
        )
    }
}

private struct ParsedOptionsFixture: ArgumentParsed {
    typealias ArgumentPayload = Payload

    var name: ParsedNameFixture
    var count: Int

    init(
        arguments: Payload
    ) throws {
        self.name = try ParsedNameFixture(
            arguments.name
        )

        guard arguments.count > 0 else {
            throw ArgumentValidationError(
                "--count must be greater than zero."
            )
        }

        self.count = arguments.count
    }

    struct Payload: ArgumentGroup {
        @Opt("name")
        var name: String?

        @Opt(
            "count",
            default: 1
        )
        var count: Int

        init() {}
    }
}

private struct ContextParsedOptionsFixture: ArgumentContextParsed {
    typealias ArgumentPayload = Payload
    typealias ArgumentContext = ParsedContextFixture

    var name: ParsedNameFixture
    var count: Int

    init(
        arguments: Payload,
        in context: ParsedContextFixture
    ) throws {
        self.name = try ParsedNameFixture(
            arguments.name ?? context.defaultName
        )

        self.count = arguments.count * context.multiplier
    }

    struct Payload: ArgumentGroup {
        @Opt("name")
        var name: String?

        @Opt(
            "count",
            default: 1
        )
        var count: Int

        init() {}
    }
}

private struct ParsedContextFixture: Sendable {
    var defaultName: String
    var multiplier: Int
}

private struct ParsedNameFixture: Sendable, Equatable {
    var rawValue: String

    init(
        _ value: String?
    ) throws {
        let trimmed = value?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard let trimmed,
              !trimmed.isEmpty else {
            throw ArgumentValidationError(
                "--name cannot be blank."
            )
        }

        self.rawValue = trimmed
    }
}
