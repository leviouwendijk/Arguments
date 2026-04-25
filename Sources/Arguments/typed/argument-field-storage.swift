final class ArgumentFieldStorage<Value: Sendable>: @unchecked Sendable {
    var value: Value

    init(
        _ value: Value
    ) {
        self.value = value
    }
}
