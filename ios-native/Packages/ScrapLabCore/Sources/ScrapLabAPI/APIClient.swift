import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import ScrapLabModels

public indirect enum JSONValue: Codable, Equatable, Sendable {
    case string(String), number(Double), bool(Bool), object([String: JSONValue]), array([JSONValue]), null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(Bool.self) { self = .bool(value) }
        else if let value = try? container.decode(Double.self) { self = .number(value) }
        else if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode([String: JSONValue].self) { self = .object(value) }
        else if let value = try? container.decode([JSONValue].self) { self = .array(value) }
        else { throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value") }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value): try container.encode(value)
        case let .number(value): try container.encode(value)
        case let .bool(value): try container.encode(value)
        case let .object(value): try container.encode(value)
        case let .array(value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}

public enum APIError: Error, Equatable, Sendable {
    case invalidURL(String)
    case invalidResponse
    case offline
    case decoding(String)
    case badRequest(message: String?, body: JSONValue?)
    case unauthorized(message: String?, body: JSONValue?)
    case planGate(feature: String?, message: String?, body: JSONValue?)
    case forbidden(message: String?, body: JSONValue?)
    case notFound(message: String?, body: JSONValue?)
    case conflict(message: String?, body: JSONValue?)
    case unprocessable(message: String?, body: JSONValue?)
    case limitReached(message: String?, body: JSONValue?)
    case rateLimited(message: String?, body: JSONValue?)
    case server(status: Int, message: String?, body: JSONValue?)
    case http(status: Int, message: String?, body: JSONValue?)
}

extension APIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let path): "Invalid URL for endpoint: \(path)"
        case .invalidResponse: "The server returned an invalid response."
        case .offline: "ScrapLab appears to be offline. Check your connection and try again."
        case .decoding(let message): "ScrapLab could not read the server response. \(message)"
        case .badRequest(let message, _), .unauthorized(let message, _), .planGate(_, let message, _), .forbidden(let message, _), .notFound(let message, _), .conflict(let message, _), .unprocessable(let message, _), .limitReached(let message, _), .rateLimited(let message, _), .server(_, let message, _), .http(_, let message, _):
            message ?? "ScrapLab returned an error."
        }
    }
}

public struct EmptyResponse: Codable, Equatable, Sendable { public init() {} }

public struct APIClient: Sendable {
    public typealias TokenProvider = @Sendable () async throws -> String?
    public typealias Transport = @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)

    private let baseURL: URL
    private let tokenProvider: TokenProvider
    private let transport: Transport

    public init(
        baseURL: URL,
        tokenProvider: @escaping TokenProvider = { nil },
        transport: @escaping Transport = APIClient.urlSessionTransport
    ) {
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
        self.transport = transport
    }

    public func send<Response: Decodable & Sendable>(_ endpoint: Endpoint, as type: Response.Type = Response.self) async throws -> Response {
        try await execute(endpoint, body: nil, contentType: nil, as: type)
    }

    public func send<Body: Encodable & Sendable, Response: Decodable & Sendable>(
        _ endpoint: Endpoint,
        body: Body,
        as type: Response.Type = Response.self
    ) async throws -> Response {
        try await execute(endpoint, body: try ModelCoding.encoder().encode(body), contentType: "application/json", as: type)
    }

    public func send<Response: Decodable & Sendable>(
        _ endpoint: Endpoint,
        multipart: MultipartFormData,
        as type: Response.Type = Response.self
    ) async throws -> Response {
        try await execute(endpoint, body: multipart.body, contentType: multipart.contentType, as: type)
    }

    private func execute<Response: Decodable & Sendable>(
        _ endpoint: Endpoint,
        body: Data?,
        contentType: String?,
        as type: Response.Type
    ) async throws -> Response {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { throw APIError.invalidURL(endpoint.path) }
        let basePath = components.path.hasSuffix("/") ? String(components.path.dropLast()) : components.path
        components.path = basePath + endpoint.path
        components.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems
        guard let url = components.url else { throw APIError.invalidURL(endpoint.path) }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let contentType { request.setValue(contentType, forHTTPHeaderField: "Content-Type") }
        if let token = try await tokenProvider(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response): (Data, HTTPURLResponse)
        do {
            (data, response) = try await transport(request)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.offline
        }
        guard (200..<300).contains(response.statusCode) else { throw Self.httpError(status: response.statusCode, data: data) }
        let responseData = data.isEmpty ? Data("{}".utf8) : data
        do {
            return try ModelCoding.decoder().decode(type, from: responseData)
        } catch {
            throw APIError.decoding(String(describing: error))
        }
    }

    private static func httpError(status: Int, data: Data) -> APIError {
        let body = try? JSONDecoder().decode(JSONValue.self, from: data)
        let object: [String: JSONValue]? = if case let .object(object) = body { object } else { nil }
        let message: String? = if let object {
            if case let .string(error) = object["error"] { error }
            else if case let .string(message) = object["message"] { message }
            else { nil }
        } else if case let .string(value) = body { value }
        else { nil }
        let upgradeRequired = if let object, case let .bool(value) = object["upgradeRequired"] { value } else { false }
        let feature: String? = if let object, case let .string(value) = object["feature"] { value } else { nil }

        switch status {
        case 400: return .badRequest(message: message, body: body)
        case 401: return .unauthorized(message: message, body: body)
        case 403 where upgradeRequired: return .planGate(feature: feature, message: message, body: body)
        case 403: return .forbidden(message: message, body: body)
        case 404: return .notFound(message: message, body: body)
        case 409: return .conflict(message: message, body: body)
        case 422: return .unprocessable(message: message, body: body)
        case 429 where upgradeRequired: return .limitReached(message: message, body: body)
        case 429: return .rateLimited(message: message, body: body)
        case 500...599: return .server(status: status, message: message, body: body)
        default: return .http(status: status, message: message, body: body)
        }
    }

    public static let urlSessionTransport: Transport = { request in
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        return (data, response)
    }
}
