public struct CommandExample: Sendable, Codable, Hashable {
    public var text: String
    public var description: String?

    public init(
        _ text: String,
        description: String? = nil
    ) {
        self.text = text
        self.description = description
    }
}

public enum CommandMetadataPatch: Sendable {
    case abstract(String)
    case discussion(String)
    case alias(CommandAlias)
    case defaultChild(CommandName)
    case example(CommandExample)
}

public extension CommandSpec {
    mutating func apply(
        _ patch: CommandMetadataPatch
    ) {
        switch patch {
        case .abstract(let value):
            abstract = value

        case .discussion(let value):
            discussion = value

        case .alias(let value):
            aliases.append(value)

        case .defaultChild(let value):
            defaultChild = value

        case .example(let value):
            examples.append(value)
        }
    }
}
