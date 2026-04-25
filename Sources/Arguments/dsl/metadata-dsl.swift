public struct DynamicMetadata: CommandComponentLowerable {
    public var patch: CommandMetadataPatch

    public init(
        _ patch: CommandMetadataPatch
    ) {
        self.patch = patch
    }

    public func lowerCommandComponent() throws -> CommandComponent {
        .metadata(patch)
    }
}

public func about(
    _ value: String
) -> DynamicMetadata {
    DynamicMetadata(
        .abstract(value)
    )
}

public func discussion(
    _ value: String
) -> DynamicMetadata {
    DynamicMetadata(
        .discussion(value)
    )
}

public func alias(
    _ value: String
) -> DynamicMetadata {
    DynamicMetadata(
        .alias(
            CommandAlias(value)
        )
    )
}

public func defaultChild(
    _ value: String
) -> DynamicMetadata {
    DynamicMetadata(
        .defaultChild(
            CommandName(value)
        )
    )
}

public func example(
    _ value: String,
    description: String? = nil
) -> DynamicMetadata {
    DynamicMetadata(
        .example(
            .init(
                value,
                description: description
            )
        )
    )
}
