import Foundation

public enum ArgumentSpecError: Error, LocalizedError, Sendable, Equatable {
    case duplicate_param(ParamName)
    case duplicate_short(Character)
    case duplicate_command(CommandName)
    case invalid_variadic_position(ParamName)

    public var errorDescription: String? {
        switch self {
        case .duplicate_param(let name):
            "Duplicate parameter '\(name.rawValue)'."

        case .duplicate_short(let short):
            "Duplicate short option '-\(short)'."

        case .duplicate_command(let name):
            "Duplicate command '\(name.rawValue)'."

        case .invalid_variadic_position(let name):
            "Variadic positional argument '\(name.rawValue)' must be the last positional argument."
        }
    }
}
