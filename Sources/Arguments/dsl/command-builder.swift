@resultBuilder
public enum CommandBuilder {
    public static func buildExpression(
        _ component: CommandComponentLowerable
    ) -> [CommandComponentLowerable] {
        [
            component,
        ]
    }

    public static func buildExpression(
        _ components: [CommandComponentLowerable]
    ) -> [CommandComponentLowerable] {
        components
    }

    public static func buildBlock(
        _ components: [CommandComponentLowerable]...
    ) -> [CommandComponentLowerable] {
        components.flatMap {
            $0
        }
    }

    public static func buildArray(
        _ components: [[CommandComponentLowerable]]
    ) -> [CommandComponentLowerable] {
        components.flatMap {
            $0
        }
    }

    public static func buildOptional(
        _ components: [CommandComponentLowerable]?
    ) -> [CommandComponentLowerable] {
        components ?? []
    }

    public static func buildEither(
        first components: [CommandComponentLowerable]
    ) -> [CommandComponentLowerable] {
        components
    }

    public static func buildEither(
        second components: [CommandComponentLowerable]
    ) -> [CommandComponentLowerable] {
        components
    }
}
