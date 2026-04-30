public protocol ArgumentPayloadProviding: Sendable {
    associatedtype ArgumentPayload: ArgumentGroup
}

public protocol ArgumentParsed: ArgumentPayloadProviding {
    init(
        arguments: ArgumentPayload
    ) throws
}

public protocol ArgumentContextParsed: ArgumentPayloadProviding {
    associatedtype ArgumentContext

    init(
        arguments: ArgumentPayload,
        in context: ArgumentContext
    ) throws
}
