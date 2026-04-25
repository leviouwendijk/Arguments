@propertyWrapper
public struct Opt<Value: ArgumentValue>: ArgumentField {
    private let storage: ArgumentFieldStorage<Value?>

    private var name: ParamName
    private var short: Character?
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
        short: Character? = nil,
        help: String? = nil
    ) {
        self.storage = ArgumentFieldStorage(
            nil
        )
        self.name = ParamName(name)
        self.short = short
        self.help = help
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
