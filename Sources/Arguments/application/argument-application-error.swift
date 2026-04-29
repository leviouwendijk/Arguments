import Foundation

public enum ArgumentApplicationError: Error, LocalizedError, Sendable, Equatable {
    case unhandled_command([String])

    public var errorDescription: String? {
        switch self {
        case .unhandled_command(let path):
            let renderedPath = path.joined(
                separator: " "
            )

            return "Unhandled command '\(renderedPath)'."
        }
    }
}
