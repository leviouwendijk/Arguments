public struct ArgumentHelpRendererConfiguration: Sendable {
    public var width: Int
    public var descriptionColumn: Int

    public init(
        width: Int = 78,
        descriptionColumn: Int = 28
    ) {
        self.width = width
        self.descriptionColumn = descriptionColumn
    }
}

public struct ArgumentHelpRenderer: Sendable {
    public var configuration: ArgumentHelpRendererConfiguration

    public init(
        configuration: ArgumentHelpRendererConfiguration = .init()
    ) {
        self.configuration = configuration
    }

    public func render(
        command: CommandSpec,
        path: [CommandName] = []
    ) -> String {
        let components = commandPathComponents(
            command: command,
            path: path
        )

        var lines: [String] = []

        appendOverview(
            command.abstract,
            to: &lines
        )

        appendUsage(
            command: command,
            components: components,
            to: &lines
        )

        appendRowsSection(
            "ARGUMENTS:",
            rows: positionalRows(command),
            to: &lines
        )

        appendRowsSection(
            "OPTIONS:",
            rows: optionRows(command) + flagRows(command) + helpRows(),
            to: &lines
        )

        appendRowsSection(
            "SUBCOMMANDS:",
            rows: commandRows(command),
            footer: subcommandFooter(
                components: components,
                command: command
            ),
            to: &lines
        )

        appendTextSection(
            "DISCUSSION:",
            text: command.discussion,
            to: &lines
        )

        appendExamples(
            command.examples,
            to: &lines
        )

        return lines
            .trimmingTrailingEmptyLines()
            .joined(
                separator: "\n"
            )
    }
}

private extension ArgumentHelpRenderer {
    struct HelpRow {
        var name: String
        var description: String?

        init(
            _ name: String,
            _ description: String? = nil
        ) {
            self.name = name
            self.description = description
        }
    }

    func commandPathComponents(
        command: CommandSpec,
        path: [CommandName]
    ) -> [String] {
        (path + [command.name]).map(\.rawValue)
    }

    func commandPath(
        _ components: [String]
    ) -> String {
        components.joined(
            separator: " "
        )
    }

    func appendOverview(
        _ overview: String?,
        to lines: inout [String]
    ) {
        guard let overview,
              !overview.isEmpty else {
            return
        }

        appendPrefixedParagraph(
            prefix: "OVERVIEW:",
            text: overview,
            to: &lines
        )
    }

    func appendUsage(
        command: CommandSpec,
        components: [String],
        to lines: inout [String]
    ) {
        appendBlankIfNeeded(
            to: &lines
        )

        appendPrefixedParagraph(
            prefix: "USAGE:",
            text: "\(commandPath(components))\(usageSuffix(for: command))",
            to: &lines
        )
    }

    func usageSuffix(
        for command: CommandSpec
    ) -> String {
        var parts: [String] = []

        if hasUserFacingOptions(command) {
            parts.append("[<options>]")
        }

        for positional in positionals(command) {
            parts.append(
                usageName(
                    for: positional
                )
            )
        }

        if !command.children.isEmpty {
            parts.append("<subcommand>")
        }

        guard !parts.isEmpty else {
            return ""
        }

        return " " + parts.joined(
            separator: " "
        )
    }

    func hasUserFacingOptions(
        _ command: CommandSpec
    ) -> Bool {
        !options(command).isEmpty || !flags(command).isEmpty
    }

    func usageName(
        for positional: PositionalSpec
    ) -> String {
        switch positional.arity {
        case .required:
            "<\(positional.name.rawValue)>"

        case .optional:
            "[<\(positional.name.rawValue)>]"

        case .variadic:
            "[<\(positional.name.rawValue)> ...]"
        }
    }

    func displayName(
        for positional: PositionalSpec
    ) -> String {
        "<\(positional.name.rawValue)>"
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
    ) -> [HelpRow] {
        positionals(command).map { positional in
            HelpRow(
                displayName(for: positional),
                described(
                    help: positional.help,
                    defaultValue: positional.defaultValue
                )
            )
        }
    }

    func optionRows(
        _ command: CommandSpec
    ) -> [HelpRow] {
        options(command).map { option in
            HelpRow(
                "\(optionNames(option)) <\(option.name.rawValue)>",
                described(
                    help: option.help,
                    defaultValue: option.defaultValue
                )
            )
        }
    }

    func optionNames(
        _ option: OptionSpec
    ) -> String {
        names(
            canonical: option.name,
            aliases: option.aliases,
            short: option.short
        )
    }

    func flagRows(
        _ command: CommandSpec
    ) -> [HelpRow] {
        flags(command).map { flag in
            HelpRow(
                flagNames(flag),
                described(
                    help: flag.help,
                    defaultValue: flag.defaultValue ? "true" : nil
                )
            )
        }
    }

    func flagNames(
        _ flag: FlagSpec
    ) -> String {
        names(
            canonical: flag.name,
            aliases: flag.aliases,
            short: flag.short
        )
    }

    func names(
        canonical: ParamName,
        aliases: [ParamName],
        short: Character?
    ) -> String {
        let longNames = ([canonical] + aliases).map {
            "--\($0.rawValue)"
        }

        if let short {
            return (["-\(short)"] + longNames).joined(
                separator: ", "
            )
        }

        return longNames.joined(
            separator: ", "
        )
    }

    func helpRows() -> [HelpRow] {
        [
            HelpRow(
                "-h, --help",
                "Show help information."
            ),
        ]
    }

    func commandRows(
        _ command: CommandSpec
    ) -> [HelpRow] {
        command.children.map { child in
            HelpRow(
                child.name.rawValue,
                child.abstract
            )
        }
    }

    func subcommandFooter(
        components: [String],
        command: CommandSpec
    ) -> String? {
        guard !command.children.isEmpty,
              let root = components.first else {
            return nil
        }

        let tail = components.dropFirst()
        let helpPath = ([root, "help"] + tail + ["<subcommand>"]).joined(
            separator: " "
        )

        return "See '\(helpPath)' for detailed help."
    }

    func appendExamples(
        _ examples: [CommandExample],
        to lines: inout [String]
    ) {
        guard !examples.isEmpty else {
            return
        }

        appendBlankIfNeeded(
            to: &lines
        )

        lines.append("EXAMPLES:")

        for example in examples {
            lines.append(
                "  \(example.text)"
            )

            if let description = example.description,
               !description.isEmpty {
                for line in wrapped(
                    description,
                    width: max(
                        20,
                        configuration.width - 4
                    )
                ) {
                    lines.append(
                        "    \(line)"
                    )
                }
            }
        }
    }

    func appendTextSection(
        _ title: String,
        text: String?,
        to lines: inout [String]
    ) {
        guard let text,
              !text.isEmpty else {
            return
        }

        appendBlankIfNeeded(
            to: &lines
        )

        lines.append(title)

        for line in wrapped(
            text,
            width: max(
                20,
                configuration.width - 2
            )
        ) {
            lines.append(
                "  \(line)"
            )
        }
    }

    func appendRowsSection(
        _ title: String,
        rows: [HelpRow],
        footer: String? = nil,
        to lines: inout [String]
    ) {
        guard !rows.isEmpty else {
            return
        }

        appendBlankIfNeeded(
            to: &lines
        )

        lines.append(title)

        for row in rows {
            appendRow(
                row,
                to: &lines
            )
        }

        if let footer,
           !footer.isEmpty {
            lines.append("")

            for line in wrapped(
                footer,
                width: max(
                    20,
                    configuration.width - 2
                )
            ) {
                lines.append(
                    "  \(line)"
                )
            }
        }
    }

    func appendRow(
        _ row: HelpRow,
        to lines: inout [String]
    ) {
        let namePrefix = "  \(row.name)"

        guard let description = row.description,
              !description.isEmpty else {
            lines.append(namePrefix)
            return
        }

        let column = configuration.descriptionColumn

        if namePrefix.count + 1 >= column {
            lines.append(namePrefix)

            for line in wrapped(
                description,
                width: max(
                    20,
                    configuration.width - column
                )
            ) {
                lines.append(
                    "\(spaces(column))\(line)"
                )
            }

            return
        }

        let initialPrefix = namePrefix + spaces(
            column - namePrefix.count
        )

        let descriptionLines = wrapped(
            description,
            width: max(
                20,
                configuration.width - column
            )
        )

        guard let first = descriptionLines.first else {
            lines.append(namePrefix)
            return
        }

        lines.append(
            "\(initialPrefix)\(first)"
        )

        for line in descriptionLines.dropFirst() {
            lines.append(
                "\(spaces(column))\(line)"
            )
        }
    }

    func appendPrefixedParagraph(
        prefix: String,
        text: String,
        to lines: inout [String]
    ) {
        let firstLineWidth = max(
            20,
            configuration.width - prefix.count - 1
        )

        let textLines = wrapped(
            text,
            width: firstLineWidth
        )

        guard let first = textLines.first else {
            lines.append(prefix)
            return
        }

        lines.append(
            "\(prefix) \(first)"
        )

        let continuationPrefix = spaces(
            prefix.count + 1
        )

        for line in textLines.dropFirst() {
            lines.append(
                "\(continuationPrefix)\(line)"
            )
        }
    }

    func appendBlankIfNeeded(
        to lines: inout [String]
    ) {
        guard !lines.isEmpty,
              lines.last != "" else {
            return
        }

        lines.append("")
    }

    func described(
        help: String?,
        defaultValue: String?
    ) -> String? {
        let cleanedHelp = help?.isEmpty == false ? help : nil

        guard let defaultValue else {
            return cleanedHelp
        }

        let suffix = "(default: \(defaultValue))"

        guard let cleanedHelp else {
            return suffix
        }

        return "\(cleanedHelp) \(suffix)"
    }

    func wrapped(
        _ text: String,
        width: Int
    ) -> [String] {
        let targetWidth = max(
            1,
            width
        )

        var lines: [String] = []

        for paragraph in text.split(
            separator: "\n",
            omittingEmptySubsequences: false
        ) {
            if paragraph.isEmpty {
                lines.append("")
                continue
            }

            lines.append(
                contentsOf: wrappedParagraph(
                    String(paragraph),
                    width: targetWidth
                )
            )
        }

        return lines
    }

    func wrappedParagraph(
        _ text: String,
        width: Int
    ) -> [String] {
        var lines: [String] = []
        var current = ""

        for rawWord in text.split(separator: " ") {
            let word = String(rawWord)

            if current.isEmpty {
                current = word
                continue
            }

            if current.count + 1 + word.count <= width {
                current += " \(word)"
                continue
            }

            lines.append(current)
            current = word
        }

        if !current.isEmpty {
            lines.append(current)
        }

        return lines
    }

    func spaces(
        _ count: Int
    ) -> String {
        String(
            repeating: " ",
            count: max(
                0,
                count
            )
        )
    }
}

private extension Array where Element == String {
    func trimmingTrailingEmptyLines() -> [String] {
        var result = self

        while result.last == "" {
            result.removeLast()
        }

        return result
    }
}
