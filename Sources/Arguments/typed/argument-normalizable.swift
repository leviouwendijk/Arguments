public protocol ArgumentNormalizable {
    mutating func normalize() throws
}

public protocol ArgumentValidatable {
    func validate() throws
}

public protocol ArgumentResolvable {
    associatedtype ResolvedArgumentValue

    func resolve() throws -> ResolvedArgumentValue
}
