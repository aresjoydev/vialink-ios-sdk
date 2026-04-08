import Foundation

/// HTTP 네트워크 클라이언트 (재시도, 지수 백오프)
final class NetworkClient: @unchecked Sendable {
    private let baseURL: String
    private let apiKey: String
    private let session: URLSession
    private let maxRetries = 3

    init(baseURL: String, apiKey: String) {
        self.baseURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        self.apiKey = apiKey

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - GET

    func get(_ path: String) async throws -> Data {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("ViaLinkSDK/1.0.4 iOS", forHTTPHeaderField: "User-Agent")

        return try await executeWithRetry(request: request)
    }

    // MARK: - POST

    func post(_ path: String, body: [String: Any]) async throws -> Data {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("ViaLinkSDK/1.0.4 iOS", forHTTPHeaderField: "User-Agent")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        return try await executeWithRetry(request: request)
    }

    // MARK: - 재시도 로직

    private func executeWithRetry(request: URLRequest, attempt: Int = 0) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw NetworkError.serverError
            }
            return data
        } catch {
            if attempt < maxRetries {
                let delay = UInt64(pow(2.0, Double(attempt))) * 1_000_000_000 // 1, 2, 4초
                try? await Task.sleep(nanoseconds: delay)
                return try await executeWithRetry(request: request, attempt: attempt + 1)
            }
            throw error
        }
    }

    enum NetworkError: Error, LocalizedError {
        case invalidURL
        case serverError

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "유효하지 않은 URL"
            case .serverError: return "서버 오류"
            }
        }
    }
}
