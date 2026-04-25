public struct CommandName: RawRepresentable, Sendable, Codable, Hashable, ExpressibleByStringLiteral {
    public var rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public init(
        _ rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public init(
        stringLiteral value: String
    ) {
        self.rawValue = value
    }
}

public struct CommandAlias: RawRepresentable, Sendable, Codable, Hashable, ExpressibleByStringLiteral {
    public var rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public init(
        _ rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public init(
        stringLiteral value: String
    ) {
        self.rawValue = value
    }
}

public struct ParamName: RawRepresentable, Sendable, Codable, Hashable, ExpressibleByStringLiteral {
    public var rawValue: String

    public init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public init(
        _ rawValue: String
    ) {
        self.rawValue = rawValue
    }

    public init(
        stringLiteral value: String
    ) {
        self.rawValue = value
    }
}
