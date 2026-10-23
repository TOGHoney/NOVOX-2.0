import Foundation

/// Unified networking error type with user-facing error descriptions
public enum NetworkError: LocalizedError, Sendable {
    case invalidURL(String)
    case unauthorized(String)
    case notFound(String)
    case serverError(statusCode: Int, message: String)
    case decodingError(String)
    case encodingError(String)
    case networkFailure(String)
    case noData
    case custom(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid request URL: \(url)"
        case .unauthorized(let msg):
            return msg.isEmpty ? "Your session has expired. Please log in again." : msg
        case .notFound(let msg):
            return msg.isEmpty ? "The requested resource was not found." : msg
        case .serverError(let code, let msg):
            if code == 400 {
                return msg.isEmpty ? "Invalid request. Please check your input." : msg
            } else if (401...499).contains(code) {
                return msg.isEmpty ? "Request failed (\(code))." : msg
            } else {
                return msg.isEmpty ? "Server error (\(code)). Please try again later." : "\(msg) (\(code))"
            }
        case .decodingError(let msg):
            return "Data format error: \(msg)"
        case .encodingError(let msg):
            return "Failed to encode request payload: \(msg)"
        case .networkFailure(let msg):
            return "Network connection failed. Verify the backend is running: \(msg)"
        case .noData:
            return "The server returned an empty response."
        case .custom(let msg):
            return msg
        }
    }
}
