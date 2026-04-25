import Foundation

public enum ArgumentParser {
    public static func parse(
        _ argv: [String],
        command: CommandSpec
    ) throws -> ParsedInvocation {
        var cursor = ArgvCursor(argv)
        var invocation = ParsedInvocation()
        var positionalIndex = 0

        let positionals = command.positionalParams()

        while let raw = cursor.peek() {
            if raw == "--" {
                cursor.advance()

                invocation.passthrough = Array(
                    argv[cursor.index..<argv.endIndex]
                )

                break
            }

            if raw.hasPrefix("--") {
                try parseLongOption(
                    raw,
                    cursor: &cursor,
                    command: command,
                    invocation: &invocation
                )

                continue
            }

            if raw.hasPrefix("-"), raw.count == 2 {
                try parseShortOption(
                    raw,
                    cursor: &cursor,
                    command: command,
                    invocation: &invocation
                )

                continue
            }

            guard positionalIndex < positionals.count else {
                throw ArgumentParseError.unexpected_argument(raw)
            }

            let positional = positionals[positionalIndex]

            try appendPositionalValue(
                raw,
                positional: positional,
                invocation: &invocation
            )

            if positional.arity != .variadic {
                positionalIndex += 1
            }

            cursor.advance()
        }

        try validateRequiredPositionals(
            positionals,
            invocation: invocation
        )

        try validateRequiredOptions(
            command.optionParams(),
            invocation: invocation
        )

        return invocation
    }

    private static func validateRequiredPositionals(
        _ positionals: [PositionalSpec],
        invocation: ParsedInvocation
    ) throws {
        for positional in positionals {
            guard positional.arity == .required else {
                continue
            }

            guard invocation.values[positional.name] != nil else {
                throw ArgumentParseError.missing_required(
                    positional.name
                )
            }
        }
    }

    private static func validateRequiredOptions(
        _ options: [OptionSpec],
        invocation: ParsedInvocation
    ) throws {
        for option in options {
            guard option.arity == .required else {
                continue
            }

            guard invocation.values[option.name] != nil else {
                throw ArgumentParseError.missing_required(
                    option.name
                )
            }
        }
    }

    private static func appendPositionalValue(
        _ value: String,
        positional: PositionalSpec,
        invocation: inout ParsedInvocation
    ) throws {
        try validateValue(
            value,
            name: positional.name,
            valueSpec: positional.value
        )

        switch positional.arity {
        case .required,
             .optional:
            invocation.values[positional.name] = value
            invocation.repeatedValues[positional.name] = [
                value,
            ]

        case .variadic:
            invocation.repeatedValues[
                positional.name,
                default: []
            ].append(value)

            invocation.values[positional.name] = value
        }
    }

    private static func appendOptionValue(
        _ value: String,
        option: OptionSpec,
        invocation: inout ParsedInvocation
    ) throws {
        try validateValue(
            value,
            name: option.name,
            valueSpec: option.value
        )

        switch option.repeatMode {
        case .single:
            guard invocation.values[option.name] == nil else {
                throw ArgumentParseError.duplicate_value(
                    option.name
                )
            }

            invocation.values[option.name] = value
            invocation.repeatedValues[option.name] = [
                value,
            ]

        case .multiple:
            invocation.repeatedValues[
                option.name,
                default: []
            ].append(value)

            invocation.values[option.name] = value
        }
    }

    private static func validateValue(
        _ value: String,
        name: ParamName,
        valueSpec: ValueSpec
    ) throws {
        do {
            try valueSpec.validate(
                value
            )
        } catch {
            throw ArgumentParseError.invalid_value(
                name,
                value,
                errorMessage(for: error)
            )
        }
    }

    private static func errorMessage(
        for error: Error
    ) -> String {
        if let error = error as? LocalizedError,
           let description = error.errorDescription {
            return description
        }

        return String(
            describing: error
        )
    }

    private static func parseLongOption(
        _ raw: String,
        cursor: inout ArgvCursor,
        command: CommandSpec,
        invocation: inout ParsedInvocation
    ) throws {
        let body = String(
            raw.dropFirst(2)
        )

        if let equalsIndex = body.firstIndex(of: "=") {
            let name = String(
                body[..<equalsIndex]
            )
            let value = String(
                body[body.index(after: equalsIndex)...]
            )

            try applyLongOption(
                name: name,
                value: value,
                original: raw,
                command: command,
                invocation: &invocation
            )

            cursor.advance()
            return
        }

        if body.hasPrefix("no-") {
            let positiveName = String(
                body.dropFirst(3)
            )

            if let flag = command.flag(named: positiveName),
               flag.negation == .automatic {
                invocation.flags[flag.name] = false
                cursor.advance()
                return
            }
        }

        if let flag = command.flag(named: body) {
            invocation.flags[flag.name] = true
            cursor.advance()
            return
        }

        if let option = command.option(named: body) {
            cursor.advance()

            guard let value = cursor.peek() else {
                throw ArgumentParseError.missing_value(raw)
            }

            try appendOptionValue(
                value,
                option: option,
                invocation: &invocation
            )

            cursor.advance()
            return
        }

        throw ArgumentParseError.unknown_option(raw)
    }

    private static func parseShortOption(
        _ raw: String,
        cursor: inout ArgvCursor,
        command: CommandSpec,
        invocation: inout ParsedInvocation
    ) throws {
        guard let short = raw.dropFirst().first else {
            throw ArgumentParseError.unknown_option(raw)
        }

        if let flag = command.flag(short: short) {
            invocation.flags[flag.name] = true
            cursor.advance()
            return
        }

        if let option = command.option(short: short) {
            cursor.advance()

            guard let value = cursor.peek() else {
                throw ArgumentParseError.missing_value(raw)
            }

            try appendOptionValue(
                value,
                option: option,
                invocation: &invocation
            )

            cursor.advance()
            return
        }

        throw ArgumentParseError.unknown_option(raw)
    }

    private static func applyLongOption(
        name: String,
        value: String,
        original: String,
        command: CommandSpec,
        invocation: inout ParsedInvocation
    ) throws {
        if let option = command.option(named: name) {
            try appendOptionValue(
                value,
                option: option,
                invocation: &invocation
            )
            return
        }

        if let flag = command.flag(named: name) {
            guard value == "true" || value == "false" else {
                throw ArgumentParseError.unknown_option(original)
            }

            invocation.flags[flag.name] = value == "true"
            return
        }

        throw ArgumentParseError.unknown_option(original)
    }
}

private extension CommandSpec {
    func positionalParams() -> [PositionalSpec] {
        params.flattenedParams.compactMap { param in
            if case .positional(let positional) = param {
                return positional
            }

            return nil
        }
    }

    func optionParams() -> [OptionSpec] {
        params.flattenedParams.compactMap { param in
            if case .option(let option) = param {
                return option
            }

            return nil
        }
    }

    func flag(
        named name: String
    ) -> FlagSpec? {
        for param in params.flattenedParams {
            if case .flag(let flag) = param,
               flag.name.rawValue == name {
                return flag
            }
        }

        return nil
    }

    func flag(
        short: Character
    ) -> FlagSpec? {
        for param in params.flattenedParams {
            if case .flag(let flag) = param,
               flag.short == short {
                return flag
            }
        }

        return nil
    }

    func option(
        named name: String
    ) -> OptionSpec? {
        for param in params.flattenedParams {
            if case .option(let option) = param,
               option.name.rawValue == name {
                return option
            }
        }

        return nil
    }

    func option(
        short: Character
    ) -> OptionSpec? {
        for param in params.flattenedParams {
            if case .option(let option) = param,
               option.short == short {
                return option
            }
        }

        return nil
    }
}
