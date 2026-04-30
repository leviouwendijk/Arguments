public enum ArgumentFieldCollector {
    public static func params<Value>(
        of value: Value
    ) throws -> [ParamSpec] {
        try fields(
            of: value
        ).map {
            try $0.lowerParam()
        }
    }

    public static func params<Value: ArgumentGroup>(
        of type: Value.Type
    ) throws -> [ParamSpec] {
        try params(
            of: Value()
        )
    }

    public static func bind<Value>(
        _ invocation: ParsedInvocation,
        into value: inout Value
    ) throws {
        var mirror = Mirror(
            reflecting: value
        )

        while true {
            for child in mirror.children {
                guard var field = child.value as? any ArgumentField else {
                    continue
                }

                try field.bind(
                    invocation
                )
            }

            guard let parent = mirror.superclassMirror else {
                break
            }

            mirror = parent
        }
    }

    public static func bind<Value: ArgumentGroup>(
        _ type: Value.Type,
        from invocation: ParsedInvocation
    ) throws -> Value {
        var value = Value()

        try bind(
            invocation,
            into: &value
        )

        return value
    }

    private static func fields<Value>(
        of value: Value
    ) -> [any ArgumentField] {
        var result: [any ArgumentField] = []
        var mirror = Mirror(
            reflecting: value
        )

        while true {
            for child in mirror.children {
                guard let field = child.value as? any ArgumentField else {
                    continue
                }

                result.append(
                    field
                )
            }

            guard let parent = mirror.superclassMirror else {
                break
            }

            mirror = parent
        }

        return result
    }
}

public extension ParsedInvocation {
    func bind<Value: ArgumentGroup>(
        _ type: Value.Type = Value.self
    ) throws -> Value {
        try ArgumentFieldCollector.bind(
            type,
            from: self
        )
    }
}
