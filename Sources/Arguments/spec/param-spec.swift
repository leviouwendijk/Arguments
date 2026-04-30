public enum ParamSpec: Sendable {
    case positional(PositionalSpec)
    case option(OptionSpec)
    case flag(FlagSpec)
    case group(ParamGroupSpec)
}

public struct PositionalSpec: Sendable {
    public var name: ParamName
    public var value: ValueSpec
    public var arity: ValueArity
    public var defaultValue: String?
    public var help: String?

    public init(
        name: ParamName,
        value: ValueSpec,
        arity: ValueArity = .required,
        defaultValue: String? = nil,
        help: String? = nil
    ) {
        self.name = name
        self.value = value
        self.arity = arity
        self.defaultValue = defaultValue
        self.help = help
    }
}

public struct OptionSpec: Sendable {
    public var name: ParamName
    public var aliases: [ParamName]
    public var short: Character?
    public var value: ValueSpec
    public var arity: ValueArity
    public var repeatMode: RepeatMode
    public var take: OptionTake
    public var defaultValue: String?
    public var help: String?

    public init(
        name: ParamName,
        aliases: [ParamName] = [],
        short: Character? = nil,
        value: ValueSpec,
        arity: ValueArity = .required,
        repeatMode: RepeatMode = .single,
        take: OptionTake = .one,
        defaultValue: String? = nil,
        help: String? = nil
    ) {
        self.name = name
        self.aliases = aliases
        self.short = short
        self.value = value
        self.arity = arity
        self.repeatMode = repeatMode
        self.take = take
        self.defaultValue = defaultValue
        self.help = help
    }
}

public struct FlagSpec: Sendable {
    public var name: ParamName
    public var aliases: [ParamName]
    public var short: Character?
    public var defaultValue: Bool
    public var negation: FlagNegation
    public var help: String?

    public init(
        name: ParamName,
        aliases: [ParamName] = [],
        short: Character? = nil,
        defaultValue: Bool = false,
        negation: FlagNegation = .automatic,
        help: String? = nil
    ) {
        self.name = name
        self.aliases = aliases
        self.short = short
        self.defaultValue = defaultValue
        self.negation = negation
        self.help = help
    }
}

public struct ParamGroupSpec: Sendable {
    public var name: String?
    public var params: [ParamSpec]
    public var rules: [CommandRule]

    public init(
        name: String? = nil,
        params: [ParamSpec] = [],
        rules: [CommandRule] = []
    ) {
        self.name = name
        self.params = params
        self.rules = rules
    }
}

public extension ParamSpec {
    var name: ParamName {
        switch self {
        case .positional(let spec):
            spec.name
        case .option(let spec):
            spec.name
        case .flag(let spec):
            spec.name
        case .group(let spec):
            ParamName(
                spec.name ?? "group"
            )
        }
    }

    var short: Character? {
        switch self {
        case .positional:
            nil
        case .option(let spec):
            spec.short
        case .flag(let spec):
            spec.short
        case .group:
            nil
        }
    }

    var longNames: [ParamName] {
        switch self {
        case .positional(let spec):
            [
                spec.name,
            ]

        case .option(let spec):
            [
                spec.name,
            ] + spec.aliases

        case .flag(let spec):
            [
                spec.name,
            ] + spec.aliases

        case .group(let spec):
            [
                ParamName(
                    spec.name ?? "group"
                ),
            ]
        }
    }
}

public extension ParamSpec {
    var flattened: [ParamSpec] {
        switch self {
        case .positional,
             .option,
             .flag:
            [
                self,
            ]

        case .group(let spec):
            spec.params.flatMap {
                $0.flattened
            }
        }
    }
}

public extension Array where Element == ParamSpec {
    var flattenedParams: [ParamSpec] {
        flatMap {
            $0.flattened
        }
    }
}
