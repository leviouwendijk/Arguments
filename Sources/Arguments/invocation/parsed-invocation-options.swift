public enum ArgumentOptionsLifecycle {
    public static func prepare<Value>(
        _ input: Value
    ) throws -> Value {
        var value = input

        if var normalizable = value as? any ArgumentNormalizable {
            try normalizable.normalize()

            if let updated = normalizable as? Value {
                value = updated
            }
        }

        if let validatable = value as? any ArgumentValidatable {
            try validatable.validate()
        }

        return value
    }
}

public extension ParsedInvocation {
    func options<Value: ArgumentGroup>(
        _ type: Value.Type = Value.self
    ) throws -> Value {
        try ArgumentOptionsLifecycle.prepare(
            bind(
                type
            )
        )
    }

    func resolved<Value>(
        _ type: Value.Type = Value.self
    ) throws -> Value.ResolvedArgumentValue
    where
        Value: ArgumentGroup & ArgumentResolvable
    {
        let value = try options(
            type
        )

        return try value.resolve()
    }

    func resolved<Value>(
        _ type: Value.Type = Value.self,
        in context: Value.ArgumentContext
    ) throws -> Value.ResolvedArgumentValue
    where
        Value: ArgumentGroup & ArgumentContextResolvable
    {
        let value = try options(
            type
        )

        return try value.resolve(
            in: context
        )
    }
}

public extension ParsedInvocation {
    func bindNormalized<Value>(
        _ type: Value.Type = Value.self
    ) throws -> Value
    where
        Value: ArgumentGroup & ArgumentNormalizable
    {
        try options(
            type
        )
    }

    func bindValidated<Value>(
        _ type: Value.Type = Value.self
    ) throws -> Value
    where
        Value: ArgumentGroup & ArgumentValidatable
    {
        try options(
            type
        )
    }

    func bindResolved<Value>(
        _ type: Value.Type = Value.self
    ) throws -> Value.ResolvedArgumentValue
    where
        Value: ArgumentGroup & ArgumentResolvable
    {
        try resolved(
            type
        )
    }

    func bindResolved<Value>(
        _ type: Value.Type = Value.self,
        in context: Value.ArgumentContext
    ) throws -> Value.ResolvedArgumentValue
    where
        Value: ArgumentGroup & ArgumentContextResolvable
    {
        try resolved(
            type,
            in: context
        )
    }
}
