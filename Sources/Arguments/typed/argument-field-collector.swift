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
