public struct ArgumentDefaultChild: Sendable, Hashable {
    public var name: CommandName?

    public init(
        name: CommandName?
    ) {
        self.name = name
    }

    public static let none = ArgumentDefaultChild(
        name: nil
    )

    public static func named(
        _ name: CommandName
    ) -> ArgumentDefaultChild {
        ArgumentDefaultChild(
            name: name
        )
    }

    public static func command(
        _ type: ArgumentCommandType
    ) -> ArgumentDefaultChild {
        ArgumentDefaultChild(
            name: CommandName(
                type.name
            )
        )
    }
}
