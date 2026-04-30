import Foundation

public struct ArgumentValidationError: Error, LocalizedError, Sendable, Equatable {
    public var message: String

    public init(
        _ message: String
    ) {
        self.message = message
    }

    public init(
        message: String
    ) {
        self.message = message
    }

    public var errorDescription: String? {
        message
    }
}
