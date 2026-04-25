public enum Arguments {
    public static func parse(
        _ argv: [String],
        spec: CommandSpec
    ) throws -> ParsedInvocation {
        let resolution = try CommandResolver.resolve(
            argv,
            root: spec
        )

        var invocation = try ArgumentParser.parse(
            resolution.remainingArgv,
            command: resolution.command
        )

        invocation.commandPath = resolution.path

        return invocation
    }
}
