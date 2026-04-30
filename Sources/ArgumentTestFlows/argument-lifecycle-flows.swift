import Arguments
import Foundation
import TestFlows

extension ArgumentFlowSuite {
    static var argumentLifecycleFlow: TestFlow {
        TestFlow(
            "argument-lifecycle",
            tags: [
                "typed",
                "binding",
                "normalize",
                "validate",
                "resolve",
                "context",
            ]
        ) {
            Step("options normalizes before returning") {
                let invocation = try ArgumentParser.parse(
                    [
                        "--name",
                        "  levi  ",
                    ],
                    command: try lifecycleSpec()
                )

                let options = try invocation.options(
                    LifecycleOptionsFixture.self
                )

                try Expect.equal(
                    options.name,
                    "levi",
                    "lifecycle.options.normalized-name"
                )
            }

            Step("options validates after normalization") {
                let invocation = try ArgumentParser.parse(
                    [
                        "--name",
                        "   ",
                        "--strict",
                    ],
                    command: try lifecycleSpec()
                )

                try Expect.throwsError(
                    "lifecycle.options.validation"
                ) {
                    _ = try invocation.options(
                        LifecycleOptionsFixture.self
                    )
                }
            }

            Step("resolved uses prepared options") {
                let invocation = try ArgumentParser.parse(
                    [
                        "--name",
                        "  levi  ",
                    ],
                    command: try lifecycleSpec()
                )

                let resolved = try invocation.resolved(
                    LifecycleOptionsFixture.self
                )

                try Expect.equal(
                    resolved.name,
                    "levi",
                    "lifecycle.resolved.name"
                )

                try Expect.equal(
                    resolved.source,
                    "plain",
                    "lifecycle.resolved.source"
                )
            }

            Step("context resolved receives context") {
                let invocation = try ArgumentParser.parse(
                    [],
                    command: try lifecycleSpec()
                )

                let resolved = try invocation.resolved(
                    LifecycleOptionsFixture.self,
                    in: LifecycleContextFixture(
                        defaultName: "context-name",
                        source: "context"
                    )
                )

                try Expect.equal(
                    resolved.name,
                    "context-name",
                    "lifecycle.context.name"
                )

                try Expect.equal(
                    resolved.source,
                    "context",
                    "lifecycle.context.source"
                )
            }

            Step("compatibility bindResolved uses lifecycle") {
                let invocation = try ArgumentParser.parse(
                    [
                        "--name",
                        "  levi  ",
                    ],
                    command: try lifecycleSpec()
                )

                let resolved = try invocation.bindResolved(
                    LifecycleOptionsFixture.self,
                    in: LifecycleContextFixture(
                        defaultName: "fallback",
                        source: "compat"
                    )
                )

                try Expect.equal(
                    resolved.name,
                    "levi",
                    "lifecycle.compat.name"
                )

                try Expect.equal(
                    resolved.source,
                    "compat",
                    "lifecycle.compat.source"
                )
            }
        }
    }
}

private func lifecycleSpec() throws -> CommandSpec {
    try cmd("lifecycle") {
        try params(
            LifecycleOptionsFixture.self
        )
    }
}

private struct LifecycleOptionsFixture:
    ArgumentGroup,
    ArgumentNormalizable,
    ArgumentValidatable,
    ArgumentResolvable,
    ArgumentContextResolvable
{
    @Opt("name")
    var name: String?

    @Flag("strict")
    var strict: Bool

    init() {}

    mutating func normalize() throws {
        name = name?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if name == "" {
            name = nil
        }
    }

    func validate() throws {
        if strict,
           name == nil {
            throw ArgumentValidationError(
                "Strict mode requires --name."
            )
        }
    }

    func resolve() throws -> LifecycleResolvedFixture {
        LifecycleResolvedFixture(
            name: name ?? "anonymous",
            source: "plain"
        )
    }

    func resolve(
        in context: LifecycleContextFixture
    ) throws -> LifecycleResolvedFixture {
        LifecycleResolvedFixture(
            name: name ?? context.defaultName,
            source: context.source
        )
    }
}

private struct LifecycleContextFixture: Sendable {
    var defaultName: String
    var source: String
}

private struct LifecycleResolvedFixture: Sendable, Equatable {
    var name: String
    var source: String
}
