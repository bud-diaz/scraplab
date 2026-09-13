import Foundation

public struct MultipartFormData: Sendable {
    public let boundary: String
    private var data = Data()

    public init(boundary: String = "ScrapLab-\(UUID().uuidString)") {
        precondition(!boundary.isEmpty && !boundary.contains("\r") && !boundary.contains("\n"), "Invalid multipart boundary")
        self.boundary = boundary
    }

    public var contentType: String { "multipart/form-data; boundary=\(boundary)" }

    public mutating func addField(name: String, value: String) {
        appendBoundary()
        append("Content-Disposition: form-data; name=\"\(quoted(name))\"\r\n\r\n")
        append(value)
        append("\r\n")
    }

    public mutating func addFile(name: String, filename: String, mimeType: String, data fileData: Data) {
        appendBoundary()
        append("Content-Disposition: form-data; name=\"\(quoted(name))\"; filename=\"\(quoted(filename))\"\r\n")
        append("Content-Type: \(headerValue(mimeType))\r\n\r\n")
        data.append(fileData)
        append("\r\n")
    }

    public var body: Data {
        var result = data
        result.append(Data("--\(boundary)--\r\n".utf8))
        return result
    }

    private mutating func appendBoundary() { append("--\(boundary)\r\n") }
    private mutating func append(_ value: String) { data.append(Data(value.utf8)) }
    private func quoted(_ value: String) -> String { value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: "\n", with: "") }
    private func headerValue(_ value: String) -> String { value.replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: "\n", with: "") }
}
