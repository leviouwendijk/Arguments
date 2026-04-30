@propertyWrapper
public struct Group<Value: ArgumentGroup>: ArgumentField {
    private let storage: ArgumentFieldStorage<Value>

    private var name: String?

    public var wrappedValue: Value {
        get {
            storage.value
        }
        nonmutating set {
            storage.value = newValue
        }
    }

    public init(
        _ name: String? = nil
    ) {
        self.storage = ArgumentFieldStorage(
            Value()
        )
        self.name = name
    }

    public init(
        wrappedValue: Value,
        _ name: String? = nil
    ) {
        self.storage = ArgumentFieldStorage(
            wrappedValue
        )
        self.name = name
    }

    public func lowerParam() throws -> ParamSpec {
        .group(
            .init(
                name: name,
                params: try ArgumentFieldCollector.params(
                    of: wrappedValue
                )
            )
        )
    }

    public mutating func bind(
        _ invocation: ParsedInvocation
    ) throws {
        var value = wrappedValue

        try ArgumentFieldCollector.bind(
            invocation,
            into: &value
        )

        wrappedValue = value
    }
}
