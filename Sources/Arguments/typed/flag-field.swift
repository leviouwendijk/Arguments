@propertyWrapper
public struct Flag: ArgumentField {
    private let storage: ArgumentFieldStorage<Bool>

    private var name: ParamName
    private var aliases: [ParamName]
    private var short: Character?
    private var defaultValue: Bool
    private var negation: FlagNegation
    private var help: String?

    public var wrappedValue: Bool {
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
        default defaultValue: Bool = false,
        negation: FlagNegation = .automatic,
        help: String? = nil
    ) {
        self.storage = ArgumentFieldStorage(
            defaultValue
        )
        self.name = ParamName(name)
        self.aliases = .aliases(
            alias,
            aliases
        )
        self.short = short
        self.defaultValue = defaultValue
        self.negation = negation
        self.help = help
    }

    public func lowerParam() throws -> ParamSpec {
        .flag(
            .init(
                name: name,
                aliases: aliases,
                short: short,
                defaultValue: defaultValue,
                negation: negation,
                help: help
            )
        )
    }

    public mutating func bind(
        _ invocation: ParsedInvocation
    ) throws {
        wrappedValue = try invocation.flag(
            name,
            default: defaultValue
        )
    }
}
