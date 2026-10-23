import Foundation

/// Primary asynchronous HTTP networking client for Linguabrief
public actor APIClient {
    
    public static let shared = APIClient()
    
    private let session: URLSession
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = AppConfig.defaultTimeout
        configuration.timeoutIntervalForResource = AppConfig.extendedTimeout
        self.session = URLSession(configuration: configuration)
        
        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.keyDecodingStrategy = .useDefaultKeys
        let isoFractional = ISO8601DateFormatter()
        isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoStandard = ISO8601DateFormatter()
        isoStandard.formatOptions = [.withInternetDateTime]
        self.jsonDecoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let dateString = try? container.decode(String.self) {
                if let date = isoFractional.date(from: dateString) ?? isoStandard.date(from: dateString) {
                    return date
                }
                let fallback = DateFormatter()
                fallback.locale = Locale(identifier: "en_US_POSIX")
                fallback.timeZone = TimeZone(secondsFromGMT: 0)
                for fmt in ["yyyy-MM-dd'T'HH:mm:ss.SSSZ", "yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd"] {
                    fallback.dateFormat = fmt
                    if let date = fallback.date(from: dateString) {
                        return date
                    }
                }
            } else if let timestamp = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: timestamp)
            }
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid date format")
            )
        }
        
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.keyEncodingStrategy = .useDefaultKeys
    }
    
    // MARK: - Generic Request Runner
    
    public func request<T: Decodable>(
        _ endpoint: Endpoint,
        body: (any Encodable)? = nil,
        timeout: TimeInterval? = nil
    ) async throws -> T {
        let urlRequest = try buildURLRequest(for: endpoint, body: body, timeout: timeout)
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch let err as URLError {
            throw NetworkError.networkFailure(err.localizedDescription)
        } catch {
            throw NetworkError.networkFailure(error.localizedDescription)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError(statusCode: -1, message: "Non-HTTP response received")
        }
        
        try validateStatusCode(httpResponse.statusCode, data: data)
        
        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch let decErr {
            // Include raw string snippet for easier debugging
            let rawSnippet = String(data: data.prefix(200), encoding: .utf8) ?? ""
            throw NetworkError.decodingError("\(decErr.localizedDescription). Snippet: \(rawSnippet)")
        }
    }
    
    public func requestVoid(
        _ endpoint: Endpoint,
        body: (any Encodable)? = nil
    ) async throws {
        let urlRequest = try buildURLRequest(for: endpoint, body: body)
        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError(statusCode: -1, message: "Non-HTTP response received")
        }
        try validateStatusCode(httpResponse.statusCode, data: data)
    }
    
    // MARK: - Private Helpers
    
    private func buildURLRequest(
        for endpoint: Endpoint,
        body: (any Encodable)?,
        timeout: TimeInterval? = nil
    ) throws -> URLRequest {
        var components = URLComponents(url: AppConfig.baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true)
        
        // Normalize paths with double slash prevention
        let fullPath = endpoint.path.hasPrefix("/") ? endpoint.path : "/\(endpoint.path)"
        let baseURLStr = AppConfig.baseURLString.hasSuffix("/") ? String(AppConfig.baseURLString.dropLast()) : AppConfig.baseURLString
        guard let resolvedURL = URL(string: "\(baseURLStr)\(fullPath)") else {
            throw NetworkError.invalidURL("\(baseURLStr)\(fullPath)")
        }
        
        var comp = URLComponents(url: resolvedURL, resolvingAgainstBaseURL: false)
        if let queryItems = endpoint.queryItems, !queryItems.isEmpty {
            comp?.queryItems = queryItems
        }
        
        guard let finalURL = comp?.url else {
            throw NetworkError.invalidURL(endpoint.path)
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = timeout ?? AppConfig.defaultTimeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if endpoint.requiresAuth {
            guard let token = KeychainManager.shared.getToken(), !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw NetworkError.unauthorized("Authentication required: No session token available.")
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                request.httpBody = try jsonEncoder.encode(AnyEncodable(body))
            } catch {
                throw NetworkError.encodingError(error.localizedDescription)
            }
        }
        
        return request
    }
    
    private func validateStatusCode(_ code: Int, data: Data) throws {
        guard (200...299).contains(code) else {
            let serverMessage = extractServerErrorMessage(from: data)
            switch code {
            case 401:
                throw NetworkError.unauthorized(serverMessage)
            case 404:
                throw NetworkError.notFound(serverMessage)
            default:
                throw NetworkError.serverError(statusCode: code, message: serverMessage)
            }
        }
    }
    
    private func extractServerErrorMessage(from data: Data) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let msg = json["message"] as? String { return msg }
            if let err = json["error"] as? String { return err }
        }
        return String(data: data.prefix(150), encoding: .utf8) ?? "HTTP Error"
    }
}

/// Type eraser for Encodable request bodies
private struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    
    init(_ encodable: any Encodable) {
        self.encodeFunc = { encoder in
            try encodable.encode(to: encoder)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}
