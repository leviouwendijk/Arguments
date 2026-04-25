@propertyWrapper
public struct Opt<Value: ArgumentValue>: ArgumentField {
    public var wrappedValue: Value?

    private var name: ParamName
    private var short: Character?
    private var help: String?

    public init(
        _ name: String,
        short: Character? = nil,
        help: String? = nil
    ) {
        self.name = ParamName(name)
        self.short = short
        self.help = help
        self.wrappedValue = nil
    }

    public func lowerParam() throws -> ParamSpec {
        .option(
            .init(
                name: name,
                short: short,
                value: ValueSpec(
                    name: Value.valueName,
                    parser: Value.parser
                ),
                arity: .optional,
                help: help
            )
        )
    }

    public mutating func bind(
        _ invocation: ParsedInvocation
    ) throws {
        wrappedValue = try invocation.value(
            name,
            as: Value.self
        )
    }
}
