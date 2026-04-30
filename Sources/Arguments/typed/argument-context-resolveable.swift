public protocol ArgumentContextResolvable {
    associatedtype ArgumentContext
    associatedtype ResolvedArgumentValue

    func resolve(
        in context: ArgumentContext
    ) throws -> ResolvedArgumentValue
}

public extension ParsedInvocation {
    func bindResolved<Value>(
        _ type: Value.Type = Value.self,
        in context: Value.ArgumentContext
    ) throws -> Value.ResolvedArgumentValue
    where
        Value: ArgumentGroup & ArgumentContextResolvable
    {
        let value = try bind(
            type
        )

        return try value.resolve(
            in: context
        )
    }
}
