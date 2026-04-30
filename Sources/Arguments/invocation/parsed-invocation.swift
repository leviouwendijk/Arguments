public struct ParsedInvocation: Sendable {
    public var commandPath: [CommandName]
    public var values: [ParamName: String]
    public var repeatedValues: [ParamName: [String]]
    public var flags: [ParamName: Bool]
    public var passthrough: [String]

    public init(
        commandPath: [CommandName] = [],
        values: [ParamName: String] = [:],
        repeatedValues: [ParamName: [String]] = [:],
        flags: [ParamName: Bool] = [:],
        passthrough: [String] = []
    ) {
        self.commandPath = commandPath
        self.values = values
        self.repeatedValues = repeatedValues
        self.flags = flags
        self.passthrough = passthrough
    }

    public func value<Value: ArgumentValue>(
        _ name: ParamName,
        as type: Value.Type = Value.self
    ) throws -> Value? {
        guard let rawValue = values[name] else {
            return nil
        }

        return try Value.parser.parse(rawValue)
    }

    public func value<Value: ArgumentValue>(
        _ name: ParamName,
        as type: Value.Type = Value.self,
        default defaultValue: Value
    ) throws -> Value {
        try value(
            name,
            as: type
        ) ?? defaultValue
    }

    public func require<Value: ArgumentValue>(
        _ name: ParamName,
        as type: Value.Type = Value.self
    ) throws -> Value {
        guard let value = try value(
            name,
            as: type
        ) else {
            throw ArgumentParseError.missing_required(
                name
            )
        }

        return value
    }

    public func values<Value: ArgumentValue>(
        _ name: ParamName,
        as type: Value.Type = Value.self
    ) throws -> [Value] {
        try (repeatedValues[name] ?? []).map {
            try Value.parser.parse($0)
        }
    }

    public func flag(
        _ name: ParamName,
        default defaultValue: Bool = false
    ) throws -> Bool {
        flags[name] ?? defaultValue
    }
}
