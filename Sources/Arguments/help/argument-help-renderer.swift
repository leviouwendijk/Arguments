public struct ArgumentHelpRenderer: Sendable {
    public init() {}

    public func render(
        command: CommandSpec,
        path: [CommandName] = []
    ) -> String {
        let fullPath = commandPath(
            command: command,
            path: path
        )

        var lines: [String] = [
            fullPath,
        ]

        if let abstract = command.abstract,
           !abstract.isEmpty {
            lines.append(
                abstract
            )
        }

        lines.append("")
        lines.append("usage:")
        lines.append(
            "    \(fullPath)\(usageSuffix(for: command))"
        )

        if let discussion = command.discussion,
           !discussion.isEmpty {
            appendSection(
                "discussion:",
                lines: [
                    discussion,
                ],
                to: &lines
            )
        }

        appendRowsSection(
            "arguments:",
            rows: positionalRows(
                command
            ),
            to: &lines
        )

        appendRowsSection(
            "options:",
            rows: optionRows(
                command
            ) + flagRows(
                command
            ),
            to: &lines
        )

        appendRowsSection(
            "commands:",
            rows: commandRows(
                command
            ),
            to: &lines
        )

        appendSection(
            "examples:",
            lines: exampleLines(
                command
            ),
            to: &lines
        )

        return lines.joined(
            separator: "\n"
        )
    }
}

private extension ArgumentHelpRenderer {
    func commandPath(
        command: CommandSpec,
        path: [CommandName]
    ) -> String {
        (path + [command.name])
            .map(\.rawValue)
            .joined(
                separator: " "
            )
    }

    func usageSuffix(
        for command: CommandSpec
    ) -> String {
        var parts: [String] = []

        for positional in positionals(
            command
        ) {
            parts.append(
                usageName(
                    for: positional
                )
            )
        }

        if !options(command).isEmpty || !flags(command).isEmpty {
            parts.append(
                "[options]"
            )
        }

        if !command.children.isEmpty {
            parts.append(
                "<command>"
            )
        }

        guard !parts.isEmpty else {
            return ""
        }

        return " " + parts.joined(
            separator: " "
        )
    }

    func usageName(
        for positional: PositionalSpec
    ) -> String {
        switch positional.arity {
        case .required:
            "<\(positional.name.rawValue)>"

        case .optional:
            "[\(positional.name.rawValue)]"

        case .variadic:
            "[\(positional.name.rawValue)...]"
        }
    }

    func positionals(
        _ command: CommandSpec
    ) -> [PositionalSpec] {
        command.params.flattenedParams.compactMap { param in
            if case .positional(let positional) = param {
                return positional
            }

            return nil
        }
    }

    func options(
        _ command: CommandSpec
    ) -> [OptionSpec] {
        command.params.flattenedParams.compactMap { param in
            if case .option(let option) = param {
                return option
            }

            return nil
        }
    }

    func flags(
        _ command: CommandSpec
    ) -> [FlagSpec] {
        command.params.flattenedParams.compactMap { param in
            if case .flag(let flag) = param {
                return flag
            }

            return nil
        }
    }

    func positionalRows(
        _ command: CommandSpec
    ) -> [(String, String?)] {
        positionals(command).map { positional in
            (
                usageName(for: positional),
                positional.help
            )
        }
    }

    func optionRows(
        _ command: CommandSpec
    ) -> [(String, String?)] {
        options(command).map { option in
            (
                "\(optionNames(option)) <\(option.value.name)>",
                option.help
            )
        }
    }

    func optionNames(
        _ option: OptionSpec
    ) -> String {
        if let short = option.short {
            return "-\(short), --\(option.name.rawValue)"
        }

        return "--\(option.name.rawValue)"
    }

    func flagRows(
        _ command: CommandSpec
    ) -> [(String, String?)] {
        flags(command).map { flag in
            (
                flagNames(flag),
                flag.help
            )
        }
    }

    func flagNames(
        _ flag: FlagSpec
    ) -> String {
        let longName: String

        switch flag.negation {
        case .automatic:
            longName = "--\(flag.name.rawValue), --no-\(flag.name.rawValue)"

        case .none:
            longName = "--\(flag.name.rawValue)"
        }

        if let short = flag.short {
            return "-\(short), \(longName)"
        }

        return longName
    }

    func commandRows(
        _ command: CommandSpec
    ) -> [(String, String?)] {
        command.children.map { child in
            (
                child.name.rawValue,
                child.abstract
            )
        }
    }

    func exampleLines(
        _ command: CommandSpec
    ) -> [String] {
        command.examples.map { example in
            guard let description = example.description,
                  !description.isEmpty else {
                return example.text
            }

            return "\(example.text)    \(description)"
        }
    }

    func appendSection(
        _ title: String,
        lines sectionLines: [String],
        to lines: inout [String]
    ) {
        guard !sectionLines.isEmpty else {
            return
        }

        lines.append("")
        lines.append(title)

        for line in sectionLines {
            lines.append(
                "    \(line)"
            )
        }
    }

    func appendRowsSection(
        _ title: String,
        rows: [(String, String?)],
        to lines: inout [String]
    ) {
        guard !rows.isEmpty else {
            return
        }

        lines.append("")
        lines.append(title)

        let nameWidth = rows
            .map { $0.0.count }
            .max() ?? 0

        for row in rows {
            let paddedName = row.0.padding(
                toLength: nameWidth,
                withPad: " ",
                startingAt: 0
            )

            if let description = row.1,
               !description.isEmpty {
                lines.append(
                    "    \(paddedName)  \(description)"
                )
            } else {
                lines.append(
                    "    \(row.0)"
                )
            }
        }
    }
}
