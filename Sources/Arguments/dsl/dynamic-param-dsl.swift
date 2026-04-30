public struct DynamicParam: ParamSpecLowerable {
    public var param: ParamSpec

    public init(
        _ param: ParamSpec
    ) {
        self.param = param
    }

    public func lowerParam() throws -> ParamSpec {
        param
    }
}

public func arg<Value: ArgumentValue>(
    _ name: String,
    as type: Value.Type = Value.self,
    arity: ValueArity = .required,
    help: String? = nil
) -> DynamicParam {
    DynamicParam(
        .positional(
            .init(
                name: ParamName(name),
                value: ValueSpec(
                    name: Value.valueName,
                    parser: Value.parser
                ),
                arity: arity,
                help: help
            )
        )
    )
}

public func arg<Value: ArgumentValue>(
    _ name: String,
    as type: Value.Type = Value.self,
    default defaultValue: Value,
    help: String? = nil
) -> DynamicParam {
    DynamicParam(
        .positional(
            .init(
                name: ParamName(name),
                value: ValueSpec(
                    name: Value.valueName,
                    parser: Value.parser
                ),
                arity: .optional,
                defaultValue: Value.raw(defaultValue),
                help: help
            )
        )
    )
}

public func opt<Value: ArgumentValue>(
    _ name: String,
    alias: String? = nil,
    aliases: [String] = [],
    short: Character? = nil,
    as type: Value.Type = Value.self,
    arity: ValueArity = .optional,
    take: OptionTake = .one,
    default defaultValue: Value? = nil,
    help: String? = nil
) -> DynamicParam {
    DynamicParam(
        .option(
            .init(
                name: ParamName(name),
                aliases: .aliases(
                    alias,
                    aliases
                ),
                short: short,
                value: ValueSpec(
                    name: Value.valueName,
                    parser: Value.parser
                ),
                arity: arity,
                take: take,
                defaultValue: defaultValue.map(Value.raw),
                help: help
            )
        )
    )
}

public func flag(
    _ name: String,
    alias: String? = nil,
    aliases: [String] = [],
    short: Character? = nil,
    default defaultValue: Bool = false,
    negation: FlagNegation = .automatic,
    help: String? = nil
) -> DynamicParam {
    DynamicParam(
        .flag(
            .init(
                name: ParamName(name),
                aliases: .aliases(
                    alias,
                    aliases
                ),
                short: short,
                defaultValue: defaultValue,
                negation: negation,
                help: help
            )
        )
    )
}

public struct DynamicParams: CommandComponentLowerable {
    public var params: [ParamSpec]

    public init(
        _ params: [ParamSpec]
    ) {
        self.params = params
    }

    public func lowerCommandComponent() throws -> CommandComponent {
        .param(
            .group(
                .init(
                    params: params
                )
            )
        )
    }
}

public func params(
    _ params: [ParamSpec]
) -> DynamicParams {
    DynamicParams(
        params
    )
}

public func params<Value: ArgumentGroup>(
    _ type: Value.Type
) throws -> DynamicParams {
    DynamicParams(
        try ArgumentFieldCollector.params(
            of: type
        )
    )
}

public func params<Value: ArgumentPayloadProviding>(
    _ type: Value.Type
) throws -> DynamicParams {
    DynamicParams(
        try ArgumentFieldCollector.params(
            of: Value.ArgumentPayload.self
        )
    )
}
