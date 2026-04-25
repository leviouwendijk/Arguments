@propertyWrapper
public struct Flag: ArgumentField {
    public var wrappedValue: Bool

    private var name: ParamName
    private var short: Character?
    private var defaultValue: Bool
    private var negation: FlagNegation
    private var help: String?

    public init(
        _ name: String,
        short: Character? = nil,
        default defaultValue: Bool = false,
        negation: FlagNegation = .automatic,
        help: String? = nil
    ) {
        self.name = ParamName(name)
        self.short = short
        self.defaultValue = defaultValue
        self.negation = negation
        self.help = help
        self.wrappedValue = defaultValue
    }

    public func lowerParam() throws -> ParamSpec {
        .flag(
            .init(
                name: name,
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
