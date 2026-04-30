public extension ParsedInvocation {
    func parse<Value>(
        _ type: Value.Type = Value.self
    ) throws -> Value
    where
        Value: ArgumentParsed
    {
        let payload = try options(
            Value.ArgumentPayload.self
        )

        return try Value(
            arguments: payload
        )
    }

    func parse<Value>(
        _ type: Value.Type = Value.self,
        in context: Value.ArgumentContext
    ) throws -> Value
    where
        Value: ArgumentContextParsed
    {
        let payload = try options(
            Value.ArgumentPayload.self
        )

        return try Value(
            arguments: payload,
            in: context
        )
    }
}
