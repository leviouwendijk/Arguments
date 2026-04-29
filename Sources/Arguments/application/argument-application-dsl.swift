public func command(
    _ path: String,
    use handler: @escaping ArgumentCommandHandler
) -> ArgumentApplicationComponent {
    .route(
        .init(
            path: [
                path,
            ],
            handler: handler
        )
    )
}

public func command(
    _ path: [String],
    use handler: @escaping ArgumentCommandHandler
) -> ArgumentApplicationComponent {
    .route(
        .init(
            path: path,
            handler: handler
        )
    )
}

public func defaultCommand(
    use handler: @escaping ArgumentCommandHandler
) -> ArgumentApplicationComponent {
    .defaultCommand(
        handler
    )
}
