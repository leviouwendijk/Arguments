public enum CommandSpecNormalizer {
    public static func normalize(
        _ spec: CommandSpec
    ) throws -> CommandSpec {
        let flattenedParams = spec.params.flattenedParams

        try validateParamNames(flattenedParams)
        try validateShortNames(flattenedParams)
        try validateVariadicPositionals(flattenedParams)
        try validateChildren(spec.children)

        var copy = spec
        copy.params = try spec.params.map(normalizeParam)
        copy.children = try spec.children.map(normalize)

        return copy
    }

    private static func normalizeParam(
        _ param: ParamSpec
    ) throws -> ParamSpec {
        switch param {
        case .positional,
             .option,
             .flag:
            param

        case .group(let group):
            .group(
                .init(
                    name: group.name,
                    params: try group.params.map(normalizeParam),
                    rules: group.rules
                )
            )
        }
    }

    private static func validateParamNames(
        _ params: [ParamSpec]
    ) throws {
        var names: Set<ParamName> = []

        for param in params {
            for name in param.longNames {
                guard !names.contains(name) else {
                    throw ArgumentSpecError.duplicate_param(name)
                }

                names.insert(name)
            }
        }
    }

    private static func validateShortNames(
        _ params: [ParamSpec]
    ) throws {
        var shorts: Set<Character> = []

        for param in params {
            guard let short = param.short else {
                continue
            }

            guard !shorts.contains(short) else {
                throw ArgumentSpecError.duplicate_short(short)
            }

            shorts.insert(short)
        }
    }

    private static func validateVariadicPositionals(
        _ params: [ParamSpec]
    ) throws {
        let positionals = params.compactMap { param in
            if case .positional(let positional) = param {
                return positional
            }

            return nil
        }

        for index in positionals.indices {
            let positional = positionals[index]

            guard positional.arity == .variadic else {
                continue
            }

            guard index == positionals.index(before: positionals.endIndex) else {
                throw ArgumentSpecError.invalid_variadic_position(
                    positional.name
                )
            }
        }
    }

    private static func validateChildren(
        _ children: [CommandSpec]
    ) throws {
        var names: Set<CommandName> = []

        for child in children {
            guard !names.contains(child.name) else {
                throw ArgumentSpecError.duplicate_command(child.name)
            }

            names.insert(child.name)
        }
    }
}
