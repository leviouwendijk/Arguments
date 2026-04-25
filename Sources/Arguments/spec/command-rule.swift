public struct CommandRule: Sendable, Codable, Hashable {
    public var name: String
    public var params: [ParamName]

    public init(
        name: String,
        params: [ParamName] = []
    ) {
        self.name = name
        self.params = params
    }
}
