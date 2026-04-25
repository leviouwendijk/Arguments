public struct CommandSpec: Sendable {
    public var name: CommandName
    public var aliases: [CommandAlias]
    public var abstract: String?
    public var discussion: String?
    public var params: [ParamSpec]
    public var children: [CommandSpec]
    public var defaultChild: CommandName?
    public var examples: [CommandExample]
    public var rules: [CommandRule]

    public init(
        name: CommandName,
        aliases: [CommandAlias] = [],
        abstract: String? = nil,
        discussion: String? = nil,
        params: [ParamSpec] = [],
        children: [CommandSpec] = [],
        defaultChild: CommandName? = nil,
        examples: [CommandExample] = [],
        rules: [CommandRule] = []
    ) {
        self.name = name
        self.aliases = aliases
        self.abstract = abstract
        self.discussion = discussion
        self.params = params
        self.children = children
        self.defaultChild = defaultChild
        self.examples = examples
        self.rules = rules
    }
}
