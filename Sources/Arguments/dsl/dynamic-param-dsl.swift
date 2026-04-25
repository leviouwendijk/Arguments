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

public func opt<Value: ArgumentValue>(
    _ name: String,
    short: Character? = nil,
    as type: Value.Type = Value.self,
    arity: ValueArity = .optional,
    repeatMode: RepeatMode = .single,
    help: String? = nil
) -> DynamicParam {
    DynamicParam(
        .option(
            .init(
                name: ParamName(name),
                short: short,
                value: ValueSpec(
                    name: Value.valueName,
                    parser: Value.parser
                ),
                arity: arity,
                repeatMode: repeatMode,
                help: help
            )
        )
    )
}

public func flag(
    _ name: String,
    short: Character? = nil,
    help: String? = nil
) -> DynamicParam {
    DynamicParam(
        .flag(
            .init(
                name: ParamName(name),
                short: short,
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
