public protocol ArgumentContextResolvable {
    associatedtype ArgumentContext
    associatedtype ResolvedArgumentValue

    func resolve(
        in context: ArgumentContext
    ) throws -> ResolvedArgumentValue
}
