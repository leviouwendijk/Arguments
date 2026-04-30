import Arguments
import TestFlows

enum ArgumentFlowSuite: TestFlowRegistry {
    static let title = "Arguments flow tests"

    static let flows: [TestFlow] = [
        commandMetadataFlow,
        dynamicParameterDSLFlow,
        parameterGroupFlow,
        helpRenderingFlow,
        argumentApplicationFlow,
        duplicateParamValidationFlow,
        duplicateShortValidationFlow,
        duplicateChildValidationFlow,
        primitiveValueParserFlow,
        propertyWrapperFieldCollectionFlow,
        propertyWrapperBindingFlow,
        typedGroupFlow,
        argvCursorFlow,
        commandResolutionFlow,
        longFlagParsingFlow,
        longOptionParsingFlow,
        shortOptionParsingFlow,
        positionalParsingFlow,
        requiredPositionalsFlow,
        optionalPositionalsFlow,
        variadicPositionalsFlow,
        terminatorPassthroughFlow,
        integratedParseFlow,
        unknownCommandFlow,
        defaultChildFlow,
        flagNegationFlow,
        requiredOptionsFlow,
        parseTimeValueValidationFlow,
        repeatableOptionsFlow,
        paramAliasFlow,
        manyOptionFlow,
        defaultValueFlow,
        decimalValueFlow,

        builderErgonomicsFlow,
        typedBindingConvenienceFlow,
        argumentLifecycleFlow,
        argumentParsedFlow,
        argumentProgramFlow,
        argumentCommandAliasFlow,

        ecCompatibilityFlow,
    ]
}

private extension ArgumentFlowSuite {
    static var argumentApplicationFlow: TestFlow {
        TestFlow(
            "argument-application",
            tags: ["application", "dispatch", "commands"]
        ) {
            Step("run default command for root invocation") {
                let spec = try cmd("agentic") {
                    try cmd("tui") {
                        flag("json")
                    }

                    try cmd("run") {
                        arg(
                            "prompt",
                            as: String.self
                        )
                    }
                }

                final class Box: @unchecked Sendable {
                    var value = ""
                }

                let box = Box()

                let application = ArgumentApplication(
                    spec: spec
                ) {
                    defaultCommand { _ in
                        box.value = "default"
                    }

                    command("tui") { _ in
                        box.value = "tui"
                    }

                    command("run") { _ in
                        box.value = "run"
                    }
                }

                try await application.run(
                    []
                )

                try Expect.equal(
                    box.value,
                    "default",
                    "application.default"
                )
            }

            Step("run routed child command") {
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

                let application = ArgumentApplication(
                    spec: spec
                ) {
                    command("run") { invocation in
                        box.prompt = try invocation.value(
                            "prompt",
                            as: String.self
                        ) ?? ""
                    }
                }

                try await application.run(
                    [
                        "run",
                        "hello",
                    ]
                )

                try Expect.equal(
                    box.prompt,
                    "hello",
                    "application.route.prompt"
                )
            }

            Step("run routed child command with explicit root name") {
                let spec = try cmd("agentic") {
                    try cmd("run") {
                        flag("stream")
                    }
                }

                final class Box: @unchecked Sendable {
                    var stream = false
                }

                let box = Box()

                let application = ArgumentApplication(
                    spec: spec
                ) {
                    command("run") { invocation in
                        box.stream = try invocation.flag(
                            "stream"
                        )
                    }
                }

                try await application.run(
                    [
                        "agentic",
                        "run",
                        "--stream",
                    ]
                )

                try Expect.true(
                    box.stream,
                    "application.explicit-root.stream"
                )
            }

            Step("unhandled command can throw") {
                let spec = try cmd("agentic") {
                    try cmd("run") {
                        flag("stream")
                    }
                }

                let application = ArgumentApplication(
                    spec: spec,
                    showsHelpForUnhandledCommand: false
                ) {}

                try await Expect.throwsError("application.unhandled") {
                    try await application.run(
                        [
                            "run",
                        ]
                    )
                }
            }
        }
    }
    static var helpRenderingFlow: TestFlow {
        TestFlow(
            "help-rendering",
            tags: ["help", "renderer", "metadata"]
        ) {
            Step("render command usage, params, and examples") {
                let spec = try cmd("agentic") {
                    try cmd("run") {
                        about("Run one prompt.")
                        discussion("Runs one prompt through the selected backend.")

                        arg(
                            "prompt",
                            as: String.self,
                            arity: .optional,
                            help: "Prompt to run."
                        )

                        opt(
                            "model",
                            short: "m",
                            as: String.self,
                            help: "Model name."
                        )

                        flag(
                            "stream",
                            short: "s",
                            help: "Stream output."
                        )

                        example(
                            "agentic run \"write tests\"",
                            description: "Run a single prompt."
                        )
                    }
                }

                let run = spec.children[0]
                let help = ArgumentHelpRenderer().render(
                    command: run,
                    path: [
                        spec.name,
                    ]
                )

                try Expect.contains(
                    help,
                    "agentic run",
                    "help.command-path"
                )

                try Expect.contains(
                    help,
                    "usage:",
                    "help.usage"
                )

                try Expect.contains(
                    help,
                    "agentic run [prompt] [options]",
                    "help.usage-line"
                )

                try Expect.contains(
                    help,
                    "arguments:",
                    "help.arguments"
                )

                try Expect.contains(
                    help,
                    "[prompt]",
                    "help.prompt"
                )

                try Expect.contains(
                    help,
                    "options:",
                    "help.options"
                )

                try Expect.contains(
                    help,
                    "-m, --model <string>",
                    "help.model"
                )

                try Expect.contains(
                    help,
                    "-s, --stream",
                    "help.stream"
                )

                try Expect.contains(
                    help,
                    "examples:",
                    "help.examples"
                )

                try Expect.contains(
                    help,
                    "agentic run \"write tests\"",
                    "help.example.text"
                )
            }

            Step("render root command list") {
                let spec = try cmd("agentic") {
                    about("Agentic runtime interface.")

                    try cmd("run") {
                        about("Run one prompt.")
                    }

                    try cmd("chat") {
                        about("Start an interactive session.")
                    }
                }

                let help = ArgumentHelpRenderer().render(
                    command: spec
                )

                try Expect.contains(
                    help,
                    "agentic",
                    "help.root.name"
                )

                try Expect.contains(
                    help,
                    "agentic <command>",
                    "help.root.usage"
                )

                try Expect.contains(
                    help,
                    "commands:",
                    "help.root.commands"
                )

                try Expect.contains(
                    help,
                    "run",
                    "help.root.run"
                )

                try Expect.contains(
                    help,
                    "chat",
                    "help.root.chat"
                )
            }

            Step("render grouped params as normal options") {
                let spec = try cmd("run") {
                    try group("output") {
                        opt(
                            "format",
                            short: "f",
                            as: String.self,
                            help: "Output format."
                        )

                        flag(
                            "json",
                            help: "Write JSON."
                        )
                    }
                }

                let help = ArgumentHelpRenderer().render(
                    command: spec
                )

                try Expect.contains(
                    help,
                    "-f, --format <string>",
                    "help.grouped.format"
                )

                try Expect.contains(
                    help,
                    "--json",
                    "help.grouped.json"
                )
            }
        }
    }
    static var propertyWrapperBindingFlow: TestFlow {
        TestFlow(
            "property-wrapper-binding",
            tags: ["typed", "wrappers", "binding"]
        ) {
            Step("bind parsed invocation into property-wrapper fields") {
                var fixture = WrapperFixture()

                let spec = try cmd("run") {
                    params(
                        try ArgumentFieldCollector.params(
                            of: fixture
                        )
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--model",
                        "gpt-5.5",
                        "--json",
                        "hello",
                    ],
                    command: spec
                )

                try ArgumentFieldCollector.bind(
                    invocation,
                    into: &fixture
                )

                try Expect.equal(
                    fixture.prompt,
                    "hello",
                    "wrapper.binding.prompt"
                )

                try Expect.equal(
                    fixture.model,
                    "gpt-5.5",
                    "wrapper.binding.model"
                )

                try Expect.true(
                    fixture.json,
                    "wrapper.binding.json"
                )
            }

            Step("missing values preserve wrapper defaults") {
                var fixture = WrapperFixture()

                let spec = try cmd("run") {
                    params(
                        try ArgumentFieldCollector.params(
                            of: fixture
                        )
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "hello",
                    ],
                    command: spec
                )

                try ArgumentFieldCollector.bind(
                    invocation,
                    into: &fixture
                )

                try Expect.equal(
                    fixture.prompt,
                    "hello",
                    "wrapper.binding.defaults.prompt"
                )

                try Expect.isNil(
                    fixture.model,
                    "wrapper.binding.defaults.model"
                )

                try Expect.false(
                    fixture.json,
                    "wrapper.binding.defaults.json"
                )
            }
        }
    }
    static var parameterGroupFlow: TestFlow {
        TestFlow(
            "parameter-groups",
            tags: ["spec", "dsl", "params", "groups", "parser"]
        ) {
            Step("group DSL preserves group in top-level params") {
                let spec = try cmd("run") {
                    try group("output") {
                        opt(
                            "format",
                            short: "f",
                            as: String.self
                        )

                        flag("json")
                    }
                }

                try Expect.equal(
                    spec.params.map { $0.name.rawValue },
                    [
                        "output",
                    ],
                    "parameter-groups.top-level.names"
                )

                guard case .group(let groupSpec) = spec.params[0] else {
                    throw TestFlowAssertionFailure(
                        label: "parameter-groups.top-level.case",
                        message: "top-level param was not a group",
                        actual: String(describing: spec.params[0]),
                        expected: "group"
                    )
                }

                try Expect.equal(
                    groupSpec.params.map { $0.name.rawValue },
                    [
                        "format",
                        "json",
                    ],
                    "parameter-groups.inner.names"
                )
            }

            Step("parser sees option inside group") {
                let spec = try cmd("run") {
                    try group("output") {
                        opt(
                            "format",
                            short: "f",
                            as: String.self
                        )
                    }
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--format",
                        "json",
                    ],
                    command: spec
                )

                try Expect.equal(
                    try invocation.value(
                        "format",
                        as: String.self
                    ),
                    "json",
                    "parameter-groups.option.value"
                )
            }

            Step("parser sees short option inside group") {
                let spec = try cmd("run") {
                    try group("output") {
                        opt(
                            "format",
                            short: "f",
                            as: String.self
                        )
                    }
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "-f",
                        "json",
                    ],
                    command: spec
                )

                try Expect.equal(
                    try invocation.value(
                        "format",
                        as: String.self
                    ),
                    "json",
                    "parameter-groups.short-option.value"
                )
            }

            Step("parser sees flag inside group") {
                let spec = try cmd("run") {
                    try group("output") {
                        flag("json")
                    }
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--json",
                    ],
                    command: spec
                )

                try Expect.true(
                    try invocation.flag("json"),
                    "parameter-groups.flag.value"
                )
            }

            Step("parser sees positional inside group") {
                let spec = try cmd("run") {
                    try group("input") {
                        arg(
                            "prompt",
                            as: String.self
                        )
                    }
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "hello",
                    ],
                    command: spec
                )

                try Expect.equal(
                    try invocation.value(
                        "prompt",
                        as: String.self
                    ),
                    "hello",
                    "parameter-groups.positional.value"
                )
            }

            Step("normalizer rejects duplicate name across group boundary") {
                try Expect.throwsError("parameter-groups.duplicate-name") {
                    _ = try cmd("run") {
                        opt(
                            "format",
                            as: String.self
                        )

                        try group("output") {
                            opt(
                                "format",
                                as: String.self
                            )
                        }
                    }
                }
            }

            Step("normalizer rejects duplicate short across group boundary") {
                try Expect.throwsError("parameter-groups.duplicate-short") {
                    _ = try cmd("run") {
                        opt(
                            "model",
                            short: "m",
                            as: String.self
                        )

                        try group("output") {
                            flag(
                                "mute",
                                short: "m"
                            )
                        }
                    }
                }
            }

            Step("nested groups parse") {
                let spec = try cmd("run") {
                    try group("outer") {
                        try group("inner") {
                            flag("json")
                        }
                    }
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--json",
                    ],
                    command: spec
                )

                try Expect.true(
                    try invocation.flag("json"),
                    "parameter-groups.nested.flag"
                )
            }
        }
    }
    static var variadicPositionalsFlow: TestFlow {
        TestFlow(
            "variadic-positionals",
            tags: ["argv", "parser", "positionals", "validation"]
        ) {
            Step("missing variadic positional does not throw") {
                let spec = try cmd("run") {
                    arg(
                        "paths",
                        as: String.self,
                        arity: .variadic
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [],
                    command: spec
                )

                try Expect.isNil(
                    try invocation.value(
                        "paths",
                        as: String.self
                    ),
                    "variadic-positionals.missing.value"
                )

                try Expect.equal(
                    try invocation.values(
                        "paths",
                        as: String.self
                    ),
                    [],
                    "variadic-positionals.missing.values"
                )
            }

            Step("variadic positional captures multiple values") {
                let spec = try cmd("run") {
                    arg(
                        "paths",
                        as: String.self,
                        arity: .variadic
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "one.txt",
                        "two.txt",
                        "three.txt",
                    ],
                    command: spec
                )

                try Expect.equal(
                    try invocation.values(
                        "paths",
                        as: String.self
                    ),
                    [
                        "one.txt",
                        "two.txt",
                        "three.txt",
                    ],
                    "variadic-positionals.values"
                )

                try Expect.equal(
                    try invocation.value(
                        "paths",
                        as: String.self
                    ),
                    "three.txt",
                    "variadic-positionals.last-value"
                )
            }

            Step("required positional before variadic parses") {
                let spec = try cmd("copy") {
                    arg(
                        "mode",
                        as: String.self
                    )

                    arg(
                        "paths",
                        as: String.self,
                        arity: .variadic
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "safe",
                        "one.txt",
                        "two.txt",
                    ],
                    command: spec
                )

                try Expect.equal(
                    try invocation.value(
                        "mode",
                        as: String.self
                    ),
                    "safe",
                    "variadic-positionals.required-before.mode"
                )

                try Expect.equal(
                    try invocation.values(
                        "paths",
                        as: String.self
                    ),
                    [
                        "one.txt",
                        "two.txt",
                    ],
                    "variadic-positionals.required-before.paths"
                )
            }

            Step("variadic positional can interleave with options") {
                let spec = try cmd("run") {
                    opt(
                        "format",
                        short: "f",
                        as: String.self
                    )

                    flag("dry-run")

                    arg(
                        "paths",
                        as: String.self,
                        arity: .variadic
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "one.txt",
                        "--format",
                        "json",
                        "two.txt",
                        "--dry-run",
                        "three.txt",
                    ],
                    command: spec
                )

                try Expect.equal(
                    try invocation.value(
                        "format",
                        as: String.self
                    ),
                    "json",
                    "variadic-positionals.interleaved.format"
                )

                try Expect.true(
                    try invocation.flag("dry-run"),
                    "variadic-positionals.interleaved.dry-run"
                )

                try Expect.equal(
                    try invocation.values(
                        "paths",
                        as: String.self
                    ),
                    [
                        "one.txt",
                        "two.txt",
                        "three.txt",
                    ],
                    "variadic-positionals.interleaved.paths"
                )
            }

            Step("variadic positional must be last positional") {
                try Expect.throwsError("variadic-positionals.not-last") {
                    _ = try cmd("run") {
                        arg(
                            "paths",
                            as: String.self,
                            arity: .variadic
                        )

                        arg(
                            "mode",
                            as: String.self
                        )
                    }
                }
            }

            Step("invalid variadic value throws during parse") {
                let spec = try cmd("run") {
                    arg(
                        "ids",
                        as: Int.self,
                        arity: .variadic
                    )
                }

                try Expect.throwsError("variadic-positionals.invalid-value") {
                    _ = try ArgumentParser.parse(
                        [
                            "1",
                            "nope",
                            "3",
                        ],
                        command: spec
                    )
                }
            }
        }
    }

    static var parseTimeValueValidationFlow: TestFlow {
        TestFlow(
            "parse-time-value-validation",
            tags: ["argv", "parser", "values", "validation"]
        ) {
            Step("invalid option value throws during parse") {
                let spec = try cmd("run") {
                    opt(
                        "count",
                        as: Int.self
                    )
                }

                try Expect.throwsError("invalid-option-value") {
                    _ = try ArgumentParser.parse(
                        [
                            "--count",
                            "nope",
                        ],
                        command: spec
                    )
                }
            }

            Step("invalid equals option value throws during parse") {
                let spec = try cmd("run") {
                    opt(
                        "count",
                        as: Int.self
                    )
                }

                try Expect.throwsError("invalid-equals-option-value") {
                    _ = try ArgumentParser.parse(
                        [
                            "--count=nope",
                        ],
                        command: spec
                    )
                }
            }

            Step("invalid positional value throws during parse") {
                let spec = try cmd("run") {
                    arg(
                        "count",
                        as: Int.self
                    )
                }

                try Expect.throwsError("invalid-positional-value") {
                    _ = try ArgumentParser.parse(
                        [
                            "nope",
                        ],
                        command: spec
                    )
                }
            }

            Step("valid typed values parse during parse") {
                let spec = try cmd("run") {
                    arg(
                        "count",
                        as: Int.self
                    )

                    opt(
                        "ratio",
                        as: Double.self
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--ratio",
                        "1.25",
                        "42",
                    ],
                    command: spec
                )

                try Expect.equal(
                    try invocation.value(
                        "count",
                        as: Int.self
                    ),
                    42,
                    "typed-values.count"
                )

                try Expect.equal(
                    try invocation.value(
                        "ratio",
                        as: Double.self
                    ),
                    1.25,
                    "typed-values.ratio"
                )
            }
        }
    }

    static var repeatableOptionsFlow: TestFlow {
        TestFlow(
            "repeatable-options",
            tags: ["argv", "parser", "options"]
        ) {
            Step("repeatable option preserves all values") {
                let spec = try cmd("run") {
                    opt(
                        "stop",
                        as: String.self,
                        take: .repeating
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

                try Expect.equal(
                    try invocation.values(
                        "stop",
                        as: String.self
                    ),
                    [
                        ".",
                        "\\n",
                    ],
                    "repeatable-options.values"
                )

                try Expect.equal(
                    try invocation.value(
                        "stop",
                        as: String.self
                    ),
                    "\\n",
                    "repeatable-options.last-value"
                )
            }

            Step("repeatable option supports equals syntax") {
                let spec = try cmd("run") {
                    opt(
                        "stop",
                        as: String.self,
                        take: .repeating
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--stop=.",
                        "--stop=\\n",
                    ],
                    command: spec
                )

                try Expect.equal(
                    try invocation.values(
                        "stop",
                        as: String.self
                    ),
                    [
                        ".",
                        "\\n",
                    ],
                    "repeatable-options.equals.values"
                )
            }

            Step("single option accepts one value") {
                let spec = try cmd("run") {
                    opt(
                        "model",
                        as: String.self
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--model",
                        "a",
                    ],
                    command: spec
                )

                try Expect.equal(
                    try invocation.value(
                        "model",
                        as: String.self
                    ),
                    "a",
                    "single-option.value"
                )

                try Expect.equal(
                    try invocation.values(
                        "model",
                        as: String.self
                    ),
                    [
                        "a",
                    ],
                    "single-option.values"
                )
            }

            Step("single option duplicate throws") {
                let spec = try cmd("run") {
                    opt(
                        "model",
                        as: String.self
                    )
                }

                try Expect.throwsError("single-option.duplicate") {
                    _ = try ArgumentParser.parse(
                        [
                            "--model",
                            "a",
                            "--model",
                            "b",
                        ],
                        command: spec
                    )
                }
            }

            Step("single option duplicate equals throws") {
                let spec = try cmd("run") {
                    opt(
                        "model",
                        as: String.self
                    )
                }

                try Expect.throwsError("single-option.duplicate.equals") {
                    _ = try ArgumentParser.parse(
                        [
                            "--model=a",
                            "--model=b",
                        ],
                        command: spec
                    )
                }
            }
        }
    }

    static var requiredOptionsFlow: TestFlow {
        TestFlow(
            "required-options",
            tags: ["argv", "parser", "options", "validation"]
        ) {
            Step("missing required option throws") {
                let spec = try cmd("run") {
                    opt(
                        "model",
                        as: String.self,
                        arity: .required
                    )
                }

                try Expect.throwsError("missing-required-option") {
                    _ = try ArgumentParser.parse(
                        [],
                        command: spec
                    )
                }
            }

            Step("present required option does not throw") {
                let spec = try cmd("run") {
                    opt(
                        "model",
                        as: String.self,
                        arity: .required
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--model",
                        "gpt-5.5",
                    ],
                    command: spec
                )

                try Expect.equal(
                    try invocation.value(
                        "model",
                        as: String.self
                    ),
                    "gpt-5.5",
                    "required-option.present"
                )
            }

            Step("missing optional option does not throw") {
                let spec = try cmd("run") {
                    opt(
                        "model",
                        as: String.self
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [],
                    command: spec
                )

                try Expect.isNil(
                    try invocation.value(
                        "model",
                        as: String.self
                    ),
                    "optional-option.missing"
                )
            }
        }
    }
    static var flagNegationFlow: TestFlow {
        TestFlow(
            "flag-negation",
            tags: ["argv", "parser", "flags"]
        ) {
            Step("parse automatic flag negation") {
                let spec = try cmd("run") {
                    flag(
                        "stream",
                        help: "Stream output."
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--no-stream",
                    ],
                    command: spec
                )

                try Expect.false(
                    try invocation.flag(
                        "stream",
                        default: true
                    ),
                    "invocation.flag.stream.negated"
                )
            }

            Step("positive flag overrides default false") {
                let spec = try cmd("run") {
                    flag("stream")
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--stream",
                    ],
                    command: spec
                )

                try Expect.true(
                    try invocation.flag("stream"),
                    "invocation.flag.stream.positive"
                )
            }

            Step("last flag value wins") {
                let spec = try cmd("run") {
                    flag("stream")
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--stream",
                        "--no-stream",
                    ],
                    command: spec
                )

                try Expect.false(
                    try invocation.flag(
                        "stream",
                        default: true
                    ),
                    "invocation.flag.stream.last-wins"
                )
            }

            Step("flag with disabled negation rejects no-prefix") {
                let spec = try cmd("run") {
                    DynamicParam(
                        .flag(
                            .init(
                                name: "stream",
                                negation: .none
                            )
                        )
                    )
                }

                try Expect.throwsError("disabled-flag-negation") {
                    _ = try ArgumentParser.parse(
                        [
                            "--no-stream",
                        ],
                        command: spec
                    )
                }
            }
        }
    }

    static var defaultChildFlow: TestFlow {
        TestFlow(
            "default-child",
            tags: ["argv", "parser", "commands"]
        ) {
            Step("resolve default child at end of argv") {
                let spec = try cmd("agentic") {
                    defaultChild("run")

                    try cmd("run") {
                        flag("json")
                    }
                }

                let invocation = try Arguments.parse(
                    [
                        "agentic",
                    ],
                    spec: spec
                )

                try Expect.equal(
                    invocation.commandPath.map(\.rawValue),
                    [
                        "agentic",
                        "run",
                    ],
                    "default-child.eof.commandPath"
                )
            }
            Step("resolve default child without consuming argv") {
                let spec = try cmd("agentic") {
                    defaultChild("run")

                    try cmd("run") {
                        arg(
                            "prompt",
                            as: String.self
                        )
                    }
                }

                let invocation = try Arguments.parse(
                    [
                        "agentic",
                        "hello",
                    ],
                    spec: spec
                )

                try Expect.equal(
                    invocation.commandPath.map(\.rawValue),
                    [
                        "agentic",
                        "run",
                    ],
                    "default-child.commandPath"
                )

                try Expect.equal(
                    try invocation.value(
                        "prompt",
                        as: String.self
                    ),
                    "hello",
                    "default-child.prompt"
                )
            }

            Step("explicit child still wins over default child") {
                let spec = try cmd("agentic") {
                    defaultChild("run")

                    try cmd("run") {
                        arg(
                            "prompt",
                            as: String.self
                        )
                    }

                    try cmd("chat") {
                        flag("ephemeral")
                    }
                }

                let invocation = try Arguments.parse(
                    [
                        "agentic",
                        "chat",
                        "--ephemeral",
                    ],
                    spec: spec
                )

                try Expect.equal(
                    invocation.commandPath.map(\.rawValue),
                    [
                        "agentic",
                        "chat",
                    ],
                    "default-child.explicit.commandPath"
                )

                try Expect.true(
                    try invocation.flag("ephemeral"),
                    "default-child.explicit.flag"
                )
            }

            Step("missing configured default child throws") {
                try Expect.throwsError("missing-default-child") {
                    _ = try cmd("agentic") {
                        defaultChild("run")

                        try cmd("chat") {
                            flag("ephemeral")
                        }
                    }
                }
            }
        }
    }
    static var unknownCommandFlow: TestFlow {
        TestFlow(
            "unknown-command",
            tags: ["argv", "parser", "commands", "diagnostics"]
        ) {
            Step("unknown child command throws") {
                let spec = try cmd("agentic") {
                    try cmd("run") {
                        flag("stream")
                    }

                    try cmd("chat") {
                        flag("ephemeral")
                    }
                }

                try Expect.throwsError("unknown-child-command") {
                    _ = try Arguments.parse(
                        [
                            "agentic",
                            "nope",
                        ],
                        spec: spec
                    )
                }
            }

            Step("root positional is still allowed when root has no children") {
                let spec = try cmd("echo") {
                    arg(
                        "message",
                        as: String.self
                    )
                }

                let invocation = try Arguments.parse(
                    [
                        "echo",
                        "hello",
                    ],
                    spec: spec
                )

                try Expect.equal(
                    try invocation.value(
                        "message",
                        as: String.self
                    ),
                    "hello",
                    "root.positionals.message"
                )
            }
        }
    }
    static var integratedParseFlow: TestFlow {
        TestFlow(
            "integrated-parse",
            tags: ["argv", "parser", "commands"]
        ) {
            Step("resolve command and parse remaining argv") {
                let spec = try cmd("agentic") {
                    try cmd("run") {
                        arg(
                            "prompt",
                            as: String.self
                        )

                        opt(
                            "model",
                            short: "m",
                            as: String.self
                        )

                        flag(
                            "stream",
                            short: "s"
                        )
                    }
                }

                let invocation = try Arguments.parse(
                    [
                        "agentic",
                        "run",
                        "--model",
                        "gpt-5.5",
                        "--stream",
                        "hello",
                    ],
                    spec: spec
                )

                try Expect.equal(
                    invocation.commandPath.map(\.rawValue),
                    [
                        "agentic",
                        "run",
                    ],
                    "invocation.commandPath"
                )

                try Expect.equal(
                    try invocation.value(
                        "prompt",
                        as: String.self
                    ),
                    "hello",
                    "invocation.value.prompt.integrated"
                )

                try Expect.equal(
                    try invocation.value(
                        "model",
                        as: String.self
                    ),
                    "gpt-5.5",
                    "invocation.value.model.integrated"
                )

                try Expect.true(
                    try invocation.flag("stream"),
                    "invocation.flag.stream.integrated"
                )
            }
        }
    }
    static var terminatorPassthroughFlow: TestFlow {
        TestFlow(
            "terminator-passthrough",
            tags: ["argv", "parser", "passthrough"]
        ) {
            Step("capture argv after terminator") {
                let spec = try cmd("run") {
                    flag("stream")
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--stream",
                        "--",
                        "--not-an-option",
                        "value",
                    ],
                    command: spec
                )

                try Expect.true(
                    try invocation.flag("stream"),
                    "invocation.flag.stream.before-terminator"
                )

                try Expect.equal(
                    invocation.passthrough,
                    [
                        "--not-an-option",
                        "value",
                    ],
                    "invocation.passthrough"
                )
            }

            Step("passthrough does not satisfy required positional") {
                let spec = try cmd("run") {
                    arg(
                        "prompt",
                        as: String.self
                    )
                }

                try Expect.throwsError("passthrough-does-not-satisfy-required") {
                    _ = try ArgumentParser.parse(
                        [
                            "--",
                            "hello",
                        ],
                        command: spec
                    )
                }
            }
        }
    }
    static var optionalPositionalsFlow: TestFlow {
        TestFlow(
            "optional-positionals",
            tags: ["argv", "parser", "positionals", "validation"]
        ) {
            Step("missing optional positional does not throw") {
                let spec = try cmd("run") {
                    arg(
                        "prompt",
                        as: String.self,
                        arity: .optional
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [],
                    command: spec
                )

                try Expect.isNil(
                    try invocation.value(
                        "prompt",
                        as: String.self
                    ),
                    "invocation.value.prompt.optional.missing"
                )
            }

            Step("present optional positional parses") {
                let spec = try cmd("run") {
                    arg(
                        "prompt",
                        as: String.self,
                        arity: .optional
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "hello",
                    ],
                    command: spec
                )

                try Expect.equal(
                    try invocation.value(
                        "prompt",
                        as: String.self
                    ),
                    "hello",
                    "invocation.value.prompt.optional.present"
                )
            }

            Step("required after optional still validates independently") {
                let spec = try cmd("run") {
                    arg(
                        "optional",
                        as: String.self,
                        arity: .optional
                    )

                    arg(
                        "required",
                        as: String.self
                    )
                }

                try Expect.throwsError("required-after-optional-missing") {
                    _ = try ArgumentParser.parse(
                        [],
                        command: spec
                    )
                }
            }
        }
    }
    static var requiredPositionalsFlow: TestFlow {
        TestFlow(
            "required-positionals",
            tags: ["argv", "parser", "positionals", "validation"]
        ) {
            Step("missing required positional throws") {
                let spec = try cmd("run") {
                    arg(
                        "prompt",
                        as: String.self
                    )
                }

                try Expect.throwsError("missing-required-positional") {
                    _ = try ArgumentParser.parse(
                        [],
                        command: spec
                    )
                }
            }

            Step("present required positional does not throw") {
                let spec = try cmd("run") {
                    arg(
                        "prompt",
                        as: String.self
                    )
                }

                try Expect.doesNotThrow("present-required-positional") {
                    _ = try ArgumentParser.parse(
                        [
                            "hello",
                        ],
                        command: spec
                    )
                }
            }
        }
    }
    static var positionalParsingFlow: TestFlow {
        TestFlow(
            "positional-parsing",
            tags: ["argv", "parser", "positionals"]
        ) {
            Step("parse positional in declaration order") {
                let spec = try cmd("run") {
                    arg(
                        "prompt",
                        as: String.self
                    )

                    arg(
                        "style",
                        as: String.self
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "hello",
                        "formal",
                    ],
                    command: spec
                )

                try Expect.equal(
                    try invocation.value(
                        "prompt",
                        as: String.self
                    ),
                    "hello",
                    "invocation.value.prompt"
                )

                try Expect.equal(
                    try invocation.value(
                        "style",
                        as: String.self
                    ),
                    "formal",
                    "invocation.value.style"
                )
            }

            Step("parse options and positionals together") {
                let spec = try cmd("run") {
                    arg(
                        "prompt",
                        as: String.self
                    )

                    opt(
                        "model",
                        short: "m",
                        as: String.self
                    )

                    flag(
                        "stream",
                        short: "s"
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--model",
                        "gpt-5.5",
                        "-s",
                        "hello",
                    ],
                    command: spec
                )

                try Expect.equal(
                    try invocation.value(
                        "prompt",
                        as: String.self
                    ),
                    "hello",
                    "invocation.value.prompt.mixed"
                )

                try Expect.equal(
                    try invocation.value(
                        "model",
                        as: String.self
                    ),
                    "gpt-5.5",
                    "invocation.value.model.mixed"
                )

                try Expect.true(
                    try invocation.flag("stream"),
                    "invocation.flag.stream.mixed"
                )
            }

            Step("unexpected positional throws") {
                let spec = try cmd("run") {
                    arg(
                        "prompt",
                        as: String.self
                    )
                }

                try Expect.throwsError("unexpected-positional") {
                    _ = try ArgumentParser.parse(
                        [
                            "hello",
                            "extra",
                        ],
                        command: spec
                    )
                }
            }
        }
    }
    static var shortOptionParsingFlow: TestFlow {
        TestFlow(
            "short-option-parsing",
            tags: ["argv", "parser", "options", "flags"]
        ) {
            Step("parse short flag") {
                let spec = try cmd("run") {
                    flag(
                        "stream",
                        short: "s"
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "-s",
                    ],
                    command: spec
                )

                try Expect.true(
                    try invocation.flag("stream"),
                    "invocation.flag.stream.short"
                )
            }

            Step("parse short option with following value") {
                let spec = try cmd("run") {
                    opt(
                        "model",
                        short: "m",
                        as: String.self
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "-m",
                        "gpt-5.5",
                    ],
                    command: spec
                )

                try Expect.equal(
                    try invocation.value(
                        "model",
                        as: String.self
                    ),
                    "gpt-5.5",
                    "invocation.value.model.short"
                )
            }

            Step("missing short option value throws") {
                let spec = try cmd("run") {
                    opt(
                        "model",
                        short: "m",
                        as: String.self
                    )
                }

                try Expect.throwsError("missing-short-option-value") {
                    _ = try ArgumentParser.parse(
                        [
                            "-m",
                        ],
                        command: spec
                    )
                }
            }

            Step("unknown short option throws") {
                let spec = try cmd("run") {
                    flag(
                        "stream",
                        short: "s"
                    )
                }

                try Expect.throwsError("unknown-short-option") {
                    _ = try ArgumentParser.parse(
                        [
                            "-x",
                        ],
                        command: spec
                    )
                }
            }
        }
    }
    static var longOptionParsingFlow: TestFlow {
        TestFlow(
            "long-option-parsing",
            tags: ["argv", "parser", "options"]
        ) {
            Step("parse long option with following value") {
                let spec = try cmd("run") {
                    opt(
                        "model",
                        as: String.self
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--model",
                        "gpt-5.5",
                    ],
                    command: spec
                )

                try Expect.equal(
                    try invocation.value(
                        "model",
                        as: String.self
                    ),
                    "gpt-5.5",
                    "invocation.value.model"
                )
            }

            Step("parse long option with equals value") {
                let spec = try cmd("run") {
                    opt(
                        "model",
                        as: String.self
                    )
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--model=gpt-5.5",
                    ],
                    command: spec
                )

                try Expect.equal(
                    try invocation.value(
                        "model",
                        as: String.self
                    ),
                    "gpt-5.5",
                    "invocation.value.model.equals"
                )
            }

            Step("missing long option value throws") {
                let spec = try cmd("run") {
                    opt(
                        "model",
                        as: String.self
                    )
                }

                try Expect.throwsError("missing-long-option-value") {
                    _ = try ArgumentParser.parse(
                        [
                            "--model",
                        ],
                        command: spec
                    )
                }
            }
        }
    }
    static var longFlagParsingFlow: TestFlow {
        TestFlow(
            "long-flag-parsing",
            tags: ["argv", "parser", "flags"]
        ) {
            Step("parse long flag into invocation") {
                let spec = try cmd("run") {
                    flag("stream")
                    flag("json")
                }

                let invocation = try ArgumentParser.parse(
                    [
                        "--stream",
                    ],
                    command: spec
                )

                try Expect.true(
                    try invocation.flag("stream"),
                    "invocation.flag.stream"
                )

                try Expect.false(
                    try invocation.flag("json"),
                    "invocation.flag.json.default"
                )
            }

            Step("unknown long flag throws") {
                let spec = try cmd("run") {
                    flag("stream")
                }

                try Expect.throwsError("unknown-long-flag") {
                    _ = try ArgumentParser.parse(
                        [
                            "--missing",
                        ],
                        command: spec
                    )
                }
            }
        }
    }

    static var commandResolutionFlow: TestFlow {
        TestFlow(
            "command-resolution",
            tags: ["argv", "parser", "commands"]
        ) {
            Step("resolve child command and leave remaining argv") {
                let spec = try cmd("agentic") {
                    try cmd("run") {
                        about("Run one prompt.")

                        flag("stream")
                    }
                }

                let resolution = try CommandResolver.resolve(
                    [
                        "agentic",
                        "run",
                        "--stream",
                        "hello",
                    ],
                    root: spec
                )

                try Expect.equal(
                    resolution.root.name.rawValue,
                    "agentic",
                    "resolution.root.name"
                )

                try Expect.equal(
                    resolution.command.name.rawValue,
                    "run",
                    "resolution.command.name"
                )

                try Expect.equal(
                    resolution.path.map(\.rawValue),
                    [
                        "agentic",
                        "run",
                    ],
                    "resolution.path"
                )

                try Expect.equal(
                    resolution.remainingArgv,
                    [
                        "--stream",
                        "hello",
                    ],
                    "resolution.remainingArgv"
                )
            }

            Step("resolve child command through alias") {
                let spec = try cmd("agentic") {
                    try cmd("run") {
                        alias("r")

                        flag("stream")
                    }
                }

                let resolution = try CommandResolver.resolve(
                    [
                        "agentic",
                        "r",
                        "--stream",
                    ],
                    root: spec
                )

                try Expect.equal(
                    resolution.command.name.rawValue,
                    "run",
                    "resolution.alias.command.name"
                )

                try Expect.equal(
                    resolution.path.map(\.rawValue),
                    [
                        "agentic",
                        "run",
                    ],
                    "resolution.alias.path"
                )

                try Expect.equal(
                    resolution.remainingArgv,
                    [
                        "--stream",
                    ],
                    "resolution.alias.remainingArgv"
                )
            }
        }
    }

    static var argvCursorFlow: TestFlow {
        TestFlow(
            "argv-cursor",
            tags: ["argv", "parser"]
        ) {
            Step("walk argv tokens") {
                var cursor = ArgvCursor(
                    [
                        "agentic",
                        "run",
                        "--stream",
                        "hello",
                    ]
                )

                try Expect.equal(
                    cursor.peek(),
                    "agentic",
                    "cursor.peek.start"
                )

                try Expect.false(
                    cursor.isEOF,
                    "cursor.isEOF.start"
                )

                cursor.advance()

                try Expect.equal(
                    cursor.peek(),
                    "run",
                    "cursor.peek.after-first-advance"
                )

                cursor.advance()
                cursor.advance()
                cursor.advance()

                try Expect.true(
                    cursor.isEOF,
                    "cursor.isEOF.end"
                )

                try Expect.isNil(
                    cursor.peek(),
                    "cursor.peek.end"
                )
            }
        }
    }

    static var commandMetadataFlow: TestFlow {
        TestFlow(
            "command-metadata",
            tags: ["spec", "dsl", "metadata"]
        ) {
            Step("build command spec with metadata") {
                let spec = try cmd("run") {
                    about("Run one prompt.")
                    discussion("Runs one prompt through the selected backend.")
                    alias("r")
                    example(
                        "agentic run \"write tests\"",
                        description: "Run a single prompt"
                    )
                }

                try Expect.equal(
                    spec.name.rawValue,
                    "run",
                    "spec.name"
                )

                try Expect.equal(
                    spec.abstract,
                    "Run one prompt.",
                    "spec.abstract"
                )

                try Expect.equal(
                    spec.discussion,
                    "Runs one prompt through the selected backend.",
                    "spec.discussion"
                )

                try Expect.equal(
                    spec.aliases.map(\.rawValue),
                    ["r"],
                    "spec.aliases"
                )

                try Expect.equal(
                    spec.examples.map(\.text),
                    ["agentic run \"write tests\""],
                    "spec.examples.text"
                )
            }
        }
    }

    static var dynamicParameterDSLFlow: TestFlow {
        TestFlow(
            "dynamic-parameter-dsl",
            tags: ["spec", "dsl", "params"]
        ) {
            Step("build positional, option, and flag params") {
                let spec = try cmd("run") {
                    arg(
                        "prompt",
                        as: String.self
                    )

                    opt(
                        "model",
                        short: "m",
                        as: String.self
                    )

                    flag(
                        "stream",
                        short: "s"
                    )
                }

                try Expect.equal(
                    spec.params.map { $0.name.rawValue },
                    [
                        "prompt",
                        "model",
                        "stream",
                    ],
                    "spec.params.names"
                )

                try Expect.equal(
                    spec.params.map(\.short),
                    [
                        nil,
                        Optional.some(Character("m")),
                        Optional.some(Character("s")),
                    ],
                    "spec.params.short"
                )
            }
        }
    }

    static var duplicateParamValidationFlow: TestFlow {
        TestFlow(
            "duplicate-param-validation",
            tags: ["spec", "validation"]
        ) {
            Check("duplicate param names throw") {
                try Expect.throwsError("duplicate-param") {
                    _ = try cmd("run") {
                        arg(
                            "input",
                            as: String.self
                        )

                        opt(
                            "input",
                            as: String.self
                        )
                    }
                }
            }
        }
    }

    static var duplicateShortValidationFlow: TestFlow {
        TestFlow(
            "duplicate-short-validation",
            tags: ["spec", "validation"]
        ) {
            Check("duplicate short names throw") {
                try Expect.throwsError("duplicate-short") {
                    _ = try cmd("run") {
                        opt(
                            "model",
                            short: "m",
                            as: String.self
                        )

                        flag(
                            "mute",
                            short: "m"
                        )
                    }
                }
            }
        }
    }

    static var duplicateChildValidationFlow: TestFlow {
        TestFlow(
            "duplicate-child-validation",
            tags: ["spec", "validation", "children"]
        ) {
            Check("duplicate child command names throw") {
                try Expect.throwsError("duplicate-child") {
                    _ = try CommandSpecNormalizer.normalize(
                        CommandSpec(
                            name: "root",
                            children: [
                                CommandSpec(
                                    name: "run"
                                ),
                                CommandSpec(
                                    name: "run"
                                ),
                            ]
                        )
                    )
                }
            }
        }
    }

    static var primitiveValueParserFlow: TestFlow {
        TestFlow(
            "primitive-value-parsers",
            tags: ["values", "parsers"]
        ) {
            Check("string parser returns raw value") {
                try Expect.equal(
                    try String.parser.parse("hello"),
                    "hello",
                    "string.parser"
                )
            }

            Check("int parser parses integers") {
                try Expect.equal(
                    try Int.parser.parse("42"),
                    42,
                    "int.parser"
                )
            }

            Check("int parser rejects invalid integers") {
                try Expect.throwsError("int.parser.invalid") {
                    _ = try Int.parser.parse("nope")
                }
            }

            Check("bool parser parses yes as true") {
                try Expect.equal(
                    try Bool.parser.parse("yes"),
                    true,
                    "bool.parser.yes"
                )
            }

            Check("double parser parses decimals") {
                try Expect.equal(
                    try Double.parser.parse("1.25"),
                    1.25,
                    "double.parser"
                )
            }

            Check("raw representable parser parses string enum cases") {
                try Expect.equal(
                    try OutputMode.parser.parse("json"),
                    .json,
                    "raw-representable.parser"
                )
            }
        }
    }

    static var propertyWrapperFieldCollectionFlow: TestFlow {
        TestFlow(
            "property-wrapper-field-collection",
            tags: ["typed", "wrappers", "params"]
        ) {
            Step("collect params from property-wrapper fields") {
                let fixture = WrapperFixture()
                let params = try ArgumentFieldCollector.params(
                    of: fixture
                )

                try Expect.equal(
                    params.map { $0.name.rawValue },
                    [
                        "prompt",
                        "model",
                        "json",
                    ],
                    "wrapper.params.names"
                )

                try Expect.equal(
                    params.map(\.short),
                    [
                        nil,
                        Optional.some(Character("m")),
                        nil,
                    ],
                    "wrapper.params.short"
                )
            }
        }
    }
}

private enum OutputMode: String, Sendable, ArgumentValue {
    case plain
    case json
}

private struct WrapperFixture: Sendable {
    @Arg(
        "prompt",
        default: ""
    )
    var prompt: String

    @Opt(
        "model",
        short: "m"
    )
    var model: String?

    @Flag("json")
    var json: Bool
}
