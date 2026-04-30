@propertyWrapper
public struct Opt<Value: ArgumentValue>: ArgumentField {
    private let storage: ArgumentFieldStorage<Value?>

    private var name: ParamName
    private var aliases: [ParamName]
    private var short: Character?
    private var take: OptionTake
    private var help: String?

    public var wrappedValue: Value? {
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
        help: String? = nil
    ) {
        self.storage = ArgumentFieldStorage(
            nil
        )
        self.name = ParamName(name)
        self.aliases = ([alias].compactMap { $0 } + aliases).map {
            ParamName($0)
        }
        self.short = short
        self.take = take
        self.help = help
    }

    public func lowerParam() throws -> ParamSpec {
        .option(
            .init(
                name: name,
                aliases: aliases,
                short: short,
                value: ValueSpec(
                    name: Value.valueName,
                    parser: Value.parser
                ),
                arity: .optional,
                take: take,
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
