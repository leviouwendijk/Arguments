@resultBuilder
public enum ParamBuilder {
    public static func buildExpression(
        _ component: ParamSpecLowerable
    ) -> [ParamSpecLowerable] {
        [
            component,
        ]
    }

    public static func buildExpression(
        _ components: [ParamSpecLowerable]
    ) -> [ParamSpecLowerable] {
        components
    }

    public static func buildBlock(
        _ components: [ParamSpecLowerable]...
    ) -> [ParamSpecLowerable] {
        components.flatMap {
            $0
        }
    }

    public static func buildArray(
        _ components: [[ParamSpecLowerable]]
    ) -> [ParamSpecLowerable] {
        components.flatMap {
            $0
        }
    }

    public static func buildOptional(
        _ components: [ParamSpecLowerable]?
    ) -> [ParamSpecLowerable] {
        components ?? []
    }

    public static func buildEither(
        first components: [ParamSpecLowerable]
    ) -> [ParamSpecLowerable] {
        components
    }

    public static func buildEither(
        second components: [ParamSpecLowerable]
    ) -> [ParamSpecLowerable] {
        components
    }
}
