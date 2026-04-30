public protocol ArgumentField: ParamSpecLowerable {
    mutating func bind(
        _ invocation: ParsedInvocation
    ) throws
}

@propertyWrapper
public struct Arg<Value: ArgumentValue>: ArgumentField {
    private let storage: ArgumentFieldStorage<Value>

    private var name: ParamName
    private var arity: ValueArity
    private var help: String?
    private var defaultValue: Value?

    public var wrappedValue: Value {
        get {
            storage.value
        }
        nonmutating set {
            storage.value = newValue
        }
    }

    public init(
        _ name: String,
        help: String? = nil,
        default defaultValue: Value
    ) {
        self.storage = ArgumentFieldStorage(
            defaultValue
        )
        self.name = ParamName(name)
        self.arity = .optional
        self.help = help
        self.defaultValue = defaultValue
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
                defaultValue: defaultValue.map(Value.raw),
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
        self.storage = ArgumentFieldStorage(
            nil
        )
        self.name = ParamName(name)
        self.arity = .optional
        self.help = help
        self.defaultValue = nil
    }
}
