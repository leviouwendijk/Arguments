extension Array where Element == ParamName {
    static func aliases(
        _ alias: String?,
        _ aliases: [String]
    ) -> Self {
        ([alias].compactMap { $0 } + aliases).map {
            ParamName($0)
        }
    }
}
