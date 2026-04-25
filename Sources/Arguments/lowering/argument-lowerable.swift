public protocol CommandSpecLowerable: Sendable {
    func lowerCommand() throws -> CommandSpec
}

public protocol CommandComponentLowerable: Sendable {
    func lowerCommandComponent() throws -> CommandComponent
}

public protocol ParamSpecLowerable: CommandComponentLowerable, Sendable {
    func lowerParam() throws -> ParamSpec
}

public extension ParamSpecLowerable {
    func lowerCommandComponent() throws -> CommandComponent {
        .param(
            try lowerParam()
        )
    }
}

extension CommandSpec: CommandComponentLowerable {
    public func lowerCommandComponent() throws -> CommandComponent {
        .child(self)
    }
}

public enum CommandComponent: Sendable {
    case param(ParamSpec)
    case child(CommandSpec)
    case metadata(CommandMetadataPatch)
    case rule(CommandRule)
}
