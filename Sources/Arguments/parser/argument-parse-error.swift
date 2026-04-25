import Foundation

public enum ArgumentParseError: Error, LocalizedError, Sendable, Equatable {
    case unknown_command(String)
    case unknown_option(String)
    case missing_value(String)
    case unexpected_argument(String)
    case missing_required(ParamName)
    case missing_default_child(CommandName)
    case duplicate_value(ParamName)
    case invalid_value(
        ParamName,
        String,
        String
    )

    public var errorDescription: String? {
        switch self {
        case .unknown_command(let value):
            "Unknown command '\(value)'."

        case .unknown_option(let value):
            "Unknown option '\(value)'."

        case .missing_value(let value):
            "Missing value for option '\(value)'."

        case .unexpected_argument(let value):
            "Unexpected argument '\(value)'."

        case .missing_required(let name):
            "Missing required argument '\(name.rawValue)'."

        case .missing_default_child(let name):
            "Missing default child command '\(name.rawValue)'."

        case .duplicate_value(let name):
            "Duplicate value for argument '\(name.rawValue)'."

        case .invalid_value(let name, let value, let reason):
            "Invalid value '\(value)' for argument '\(name.rawValue)': \(reason)"
        }
    }
}
