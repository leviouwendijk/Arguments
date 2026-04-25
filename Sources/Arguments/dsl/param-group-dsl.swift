public func group(
    _ name: String? = nil,
    @ParamBuilder _ build: () throws -> [ParamSpecLowerable]
) throws -> DynamicParam {
    var params: [ParamSpec] = []

    for lowerable in try build() {
        params.append(
            try lowerable.lowerParam()
        )
    }

    return DynamicParam(
        .group(
            .init(
                name: name,
                params: params
            )
        )
    )
}
