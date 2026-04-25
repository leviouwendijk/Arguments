public struct ArgvCursor: Sendable, Hashable {
    public var argv: [String]
    public var index: Int

    public init(
        _ argv: [String],
        index: Int = 0
    ) {
        self.argv = argv
        self.index = index
    }

    public var isEOF: Bool {
        index >= argv.endIndex
    }

    public func peek() -> String? {
        guard !isEOF else {
            return nil
        }

        return argv[index]
    }

    public mutating func advance() {
        guard !isEOF else {
            return
        }

        index = argv.index(
            after: index
        )
    }
}
