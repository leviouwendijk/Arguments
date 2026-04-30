@propertyWrapper
public struct Opt<Value: ArgumentBindingValue>: ArgumentField {
    private let storage: ArgumentFieldStorage<Value>

    private var name: ParamName
    private var aliases: [ParamName]
    private var short: Character?
    private var take: OptionTake
    private var defaultValue: Value?
    private var help: String?

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
        alias: String? = nil,
        aliases: [String] = [],
        short: Character? = nil,
        take: OptionTake = .one,
        default defaultValue: Value,
        help: String? = nil
    ) {
        self.storage = ArgumentFieldStorage(
            defaultValue
        )
        self.name = ParamName(
            name
        )
        self.aliases = .aliases(
            alias,
            aliases
        )
        self.short = short
        self.take = take
        self.defaultValue = defaultValue
        self.help = help
    }

    public func lowerParam() throws -> ParamSpec {
        .option(
            .init(
                name: name,
                aliases: aliases,
                short: short,
                value: ValueSpec(
                    name: Value.argumentValueName,
                    validator: Value.argumentValueValidator
                ),
                arity: .optional,
                take: take,
                defaultValue: defaultValue.flatMap(
                    Value.rawArgumentValue
                ),
                help: help
            )
        )
    }

    public mutating func bind(
        _ invocation: ParsedInvocation
    ) throws {
        if let rawValue = invocation.values[name] {
            wrappedValue = try Value.parseArgumentValue(
                rawValue
            )
            return
        }

        if let defaultValue {
            wrappedValue = defaultValue
        }
    }
}

public extension Opt where Value: ExpressibleByNilLiteral {
    init(
        _ name: String,
        alias: String? = nil,
        aliases: [String] = [],
        short: Character? = nil,
        take: OptionTake = .one,
        help: String? = nil
    ) {
        self.storage = ArgumentFieldStorage(
            nil
        )
        self.name = ParamName(
            name
        )
        self.aliases = .aliases(
            alias,
            aliases
        )
        self.short = short
        self.take = take
        self.defaultValue = nil
        self.help = help
    }
}
