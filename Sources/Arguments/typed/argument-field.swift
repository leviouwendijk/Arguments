public protocol ArgumentField: ParamSpecLowerable {
    mutating func bind(
        _ invocation: ParsedInvocation
    ) throws
}

@propertyWrapper
public struct Arg<Value: ArgumentValue>: ArgumentField {
    public var wrappedValue: Value

    private var name: ParamName
    private var arity: ValueArity
    private var help: String?
    private var defaultValue: Value?

    public init(
        _ name: String,
        help: String? = nil,
        default defaultValue: Value
    ) {
        self.name = ParamName(name)
        self.arity = .required
        self.help = help
        self.defaultValue = defaultValue
        self.wrappedValue = defaultValue
    }

    public func lowerParam() throws -> ParamSpec {
        .positional(
            .init(
                name: name,
                value: ValueSpec(
                    name: Value.valueName,
                    parser: Value.parser
                ),
                arity: arity,
                help: help
            )
        )
    }

    public mutating func bind(
        _ invocation: ParsedInvocation
    ) throws {
        if let value = try invocation.value(
            name,
            as: Value.self
        ) {
            wrappedValue = value
            return
        }

        if let defaultValue {
            wrappedValue = defaultValue
        }
    }
}

public extension Arg where Value: ExpressibleByNilLiteral {
    init(
        _ name: String,
        help: String? = nil
    ) {
        self.name = ParamName(name)
        self.arity = .optional
        self.help = help
        self.defaultValue = nil
        self.wrappedValue = nil
    }
}
