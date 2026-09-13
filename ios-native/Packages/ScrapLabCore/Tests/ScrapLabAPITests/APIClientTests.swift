import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import ScrapLabAPI

private struct Response: Codable, Equatable, Sendable { let createdAt: Date }
private struct RequestBody: Codable, Sendable { let childAge: Int }

@Test func clientAddsBearerTokenAndDecodesSnakeCaseResponse() async throws {
    let transport: APIClient.Transport = { request in
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer secret")
        let data = #"{"created_at":"2026-09-11T12:34:56Z"}"#.data(using: .utf8)!
        return (data, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
    let client = APIClient(
        baseURL: URL(string: "https://example.com")!,
        tokenProvider: { "secret" },
        transport: transport
    )

    let response: Response = try await client.send(Endpoint(path: "/api/test", method: .get))
    #expect(response.createdAt.timeIntervalSince1970 > 0)
}

@Test func clientEncodesRequestBodiesUsingCamelCaseKeys() async throws {
    let transport: APIClient.Transport = { request in
        let body = try #require(request.httpBody)
        let object = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(object["childAge"] as? Int == 9)
        #expect(object["child_age"] == nil)
        return (Data("{}".utf8), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
    let client = APIClient(baseURL: URL(string: "https://example.com")!, transport: transport)
    let _: EmptyResponse = try await client.send(
        Endpoint(path: "/api/test", method: .post), body: RequestBody(childAge: 9)
    )
}

@Test func nonStringAPIErrorBodyIsPreservedInTypedMapping() async throws {
    let transport: APIClient.Transport = { request in
        let data = #"{"error":{"fieldErrors":{"age":["Too young"]}}}"#.data(using: .utf8)!
        return (data, HTTPURLResponse(url: request.url!, statusCode: 400, httpVersion: nil, headerFields: nil)!)
    }
    let client = APIClient(baseURL: URL(string: "https://example.com")!, transport: transport)

    await #expect(throws: APIError.self) {
        let _: EmptyResponse = try await client.send(Endpoint(path: "/api/test", method: .get))
    }
    do {
        let _: EmptyResponse = try await client.send(Endpoint(path: "/api/test", method: .get))
        Issue.record("Expected request to fail")
    } catch APIError.badRequest(let message, let body) {
        #expect(message == nil)
        #expect(body != nil)
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

@Test func planGateAndLimitErrorsDecodeUpgradeRequiredSemantics() async throws {
    let planGateClient = APIClient(baseURL: URL(string: "https://example.com")!, transport: { _ in
        let data = #"{"error":"Plus is required","upgradeRequired":true,"feature":"photoScan"}"#.data(using: .utf8)!
        return (data, HTTPURLResponse(url: URL(string: "https://example.com/api/test")!, statusCode: 403, httpVersion: nil, headerFields: nil)!)
    })

    do {
        let _: EmptyResponse = try await planGateClient.send(Endpoint(path: "/api/test", method: .get))
        Issue.record("Expected plan gate")
    } catch APIError.planGate(let feature, let message, _) {
        #expect(feature == "photoScan")
        #expect(message == "Plus is required")
    } catch {
        Issue.record("Unexpected error: \(error)")
    }

    let limitClient = APIClient(baseURL: URL(string: "https://example.com")!, transport: { _ in
        let data = #"{"message":"Daily limit reached","upgradeRequired":true}"#.data(using: .utf8)!
        return (data, HTTPURLResponse(url: URL(string: "https://example.com/api/test")!, statusCode: 429, httpVersion: nil, headerFields: nil)!)
    })

    do {
        let _: EmptyResponse = try await limitClient.send(Endpoint(path: "/api/test", method: .get))
        Issue.record("Expected limit reached")
    } catch APIError.limitReached(let message, _) {
        #expect(message == "Daily limit reached")
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

@Test func transportAndDecodingFailuresMapToAPIError() async throws {
    let offlineClient = APIClient(baseURL: URL(string: "https://example.com")!, transport: { _ in
        throw URLError(.notConnectedToInternet)
    })
    await #expect(throws: APIError.offline) {
        let _: EmptyResponse = try await offlineClient.send(Endpoint(path: "/api/test", method: .get))
    }

    let decodingClient = APIClient(baseURL: URL(string: "https://example.com")!, transport: { request in
        let data = #"{"wrong_key":"2026-09-11T12:34:56Z"}"#.data(using: .utf8)!
        return (data, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    })
    await #expect(throws: APIError.self) {
        let _: Response = try await decodingClient.send(Endpoint(path: "/api/test", method: .get))
    }
    do {
        let _: Response = try await decodingClient.send(Endpoint(path: "/api/test", method: .get))
        Issue.record("Expected decoding error")
    } catch APIError.decoding(let message) {
        #expect(message.contains("createdAt"))
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

@Test func localizedDescriptionPreservesServerMessage() {
    let error = APIError.limitReached(message: "Daily limit reached", body: nil)
    #expect(error.localizedDescription == "Daily limit reached")
}

@Test func multipartBuilderEmitsFieldsFilesAndClosingBoundary() throws {
    var multipart = MultipartFormData(boundary: "Boundary-123")
    multipart.addField(name: "note", value: "hello")
    multipart.addFile(name: "image", filename: "photo.jpg", mimeType: "image/jpeg", data: Data([0x41, 0x42]))

    let text = try #require(String(data: multipart.body, encoding: .utf8))
    #expect(multipart.contentType == "multipart/form-data; boundary=Boundary-123")
    #expect(text.contains("name=\"note\"\r\n\r\nhello"))
    #expect(text.contains("filename=\"photo.jpg\""))
    #expect(text.hasSuffix("--Boundary-123--\r\n"))
}
