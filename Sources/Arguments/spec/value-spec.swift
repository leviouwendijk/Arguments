public struct AnyArgumentValueValidator: Sendable {
    private let validateBody: @Sendable (String) throws -> Void

    public init(
        _ validateBody: @escaping @Sendable (String) throws -> Void
    ) {
        self.validateBody = validateBody
    }

    public init<Value: Sendable>(
        _ parser: AnyArgumentValueParser<Value>
    ) {
        self.validateBody = { rawValue in
            _ = try parser.parse(rawValue)
        }
    }

    public func validate(
        _ rawValue: String
    ) throws {
        try validateBody(rawValue)
    }

    public static var passthrough: Self {
        .init { _ in }
    }
}

public struct ValueSpec: Sendable {
    public var name: String
    public var validator: AnyArgumentValueValidator

    public init(
        name: String,
        validator: AnyArgumentValueValidator = .passthrough
    ) {
        self.name = name
        self.validator = validator
    }

    public init<Value: ArgumentValue>(
        name: String,
        parser: AnyArgumentValueParser<Value>
    ) {
        self.name = name
        self.validator = AnyArgumentValueValidator(
            parser
        )
    }

    public func validate(
        _ rawValue: String
    ) throws {
        try validator.validate(rawValue)
    }
}

public enum ValueArity: String, Sendable, Codable, Hashable, CaseIterable {
    case required
    case optional
    case variadic
}

public enum RepeatMode: String, Sendable, Codable, Hashable, CaseIterable {
    case single
    case multiple
}

public enum FlagNegation: String, Sendable, Codable, Hashable, CaseIterable {
    case none
    case automatic
}
