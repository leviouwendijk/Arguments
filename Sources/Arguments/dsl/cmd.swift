public func cmd(
    _ name: String,
    @CommandBuilder _ build: () throws -> [CommandComponentLowerable]
) throws -> CommandSpec {
    var spec = CommandSpec(
        name: CommandName(name)
    )

    for lowerable in try build() {
        let component = try lowerable.lowerCommandComponent()

        switch component {
        case .param(let param):
            spec.params.append(param)

        case .child(let child):
            spec.children.append(child)

        case .metadata(let patch):
            spec.apply(patch)

        case .rule(let rule):
            spec.rules.append(rule)
        }
    }

    return try CommandSpecNormalizer.normalize(spec)
}
