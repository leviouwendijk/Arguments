import Foundation

public struct AnyArgumentValueParser<Value: Sendable>: Sendable {
    private let parseBody: @Sendable (String) throws -> Value

    public init(
        _ parseBody: @escaping @Sendable (String) throws -> Value
    ) {
        self.parseBody = parseBody
    }

    public func parse(
        _ rawValue: String
    ) throws -> Value {
        try parseBody(rawValue)
    }
}

public protocol ArgumentValue: Sendable {
    static var parser: AnyArgumentValueParser<Self> { get }
    static var valueName: String { get }
}

public enum ArgumentValueParseError: Error, LocalizedError, Sendable, Equatable {
    case invalid_value(
        value: String,
        type: String
    )

    public var errorDescription: String? {
        switch self {
        case .invalid_value(let value, let type):
            "Invalid value '\(value)' for \(type)."
        }
    }
}

extension String: ArgumentValue {
    public static var parser: AnyArgumentValueParser<String> {
        .init { rawValue in
            rawValue
        }
    }

    public static var valueName: String {
        "string"
    }
}

extension Int: ArgumentValue {
    public static var parser: AnyArgumentValueParser<Int> {
        .init { rawValue in
            guard let value = Int(rawValue) else {
                throw ArgumentValueParseError.invalid_value(
                    value: rawValue,
                    type: valueName
                )
            }

            return value
        }
    }

    public static var valueName: String {
        "int"
    }
}

extension Bool: ArgumentValue {
    public static var parser: AnyArgumentValueParser<Bool> {
        .init { rawValue in
            switch rawValue.lowercased() {
            case "true", "yes", "y", "1":
                return true
            case "false", "no", "n", "0":
                return false
            default:
                throw ArgumentValueParseError.invalid_value(
                    value: rawValue,
                    type: valueName
                )
            }
        }
    }

    public static var valueName: String {
        "bool"
    }
}

extension Double: ArgumentValue {
    public static var parser: AnyArgumentValueParser<Double> {
        .init { rawValue in
            guard let value = Double(rawValue) else {
                throw ArgumentValueParseError.invalid_value(
                    value: rawValue,
                    type: valueName
                )
            }

            return value
        }
    }

    public static var valueName: String {
        "double"
    }
}

extension Float: ArgumentValue {
    public static var parser: AnyArgumentValueParser<Float> {
        .init { rawValue in
            guard let value = Float(rawValue) else {
                throw ArgumentValueParseError.invalid_value(
                    value: rawValue,
                    type: valueName
                )
            }

            return value
        }
    }

    public static var valueName: String {
        "float"
    }
}

extension Decimal: ArgumentValue {
    public static var parser: AnyArgumentValueParser<Decimal> {
        .init { rawValue in
            guard let value = Decimal(string: rawValue) else {
                throw ArgumentValueParseError.invalid_value(
                    value: rawValue,
                    type: valueName
                )
            }

            return value
        }
    }

    public static var valueName: String {
        "decimal"
    }
}

public extension ArgumentValue where Self: RawRepresentable, RawValue == String {
    static var parser: AnyArgumentValueParser<Self> {
        .init { rawValue in
            guard let value = Self(rawValue: rawValue) else {
                throw ArgumentValueParseError.invalid_value(
                    value: rawValue,
                    type: valueName
                )
            }

            return value
        }
    }

    static var valueName: String {
        String(
            describing: Self.self
        )
    }
}
