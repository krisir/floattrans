import Foundation
import XCTest

@testable import LiveEnglish

final class LLMModelRouterTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockLLMURLProtocol.reset()
    }

    func testHTTPFailureFallsThroughToNextModelInConfiguredOrder() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockLLMURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let router = LLMModelRouter(
            models: [
                LLMModelConfiguration(
                    name: "first", baseURL: "https://first.mock/v1", model: "first-model", timeoutSeconds: 2),
                LLMModelConfiguration(
                    name: "second", baseURL: "https://second.mock/v1", model: "second-model", timeoutSeconds: 2),
            ],
            timeoutSeconds: 2,
            session: session)

        let translated = try await router.translate("Hello", from: .english, to: .russian)

        XCTAssertEqual(translated, "Привет")
        XCTAssertEqual(MockLLMURLProtocol.requestedHosts, ["first.mock", "second.mock"])
    }

    func testNewModelStartsWithTheEditableDefaultPrompt() {
        let model = LLMModelConfiguration(name: "test", baseURL: "https://mock.example/v1", model: "test-model")
        XCTAssertEqual(model.systemPrompt, LLMTranslationPrompt.defaultSystemPrompt)
        XCTAssertTrue(model.systemPrompt.contains("Return only the translated text"))
    }
}

private final class MockLLMURLProtocol: URLProtocol {
    private static let recorder = ModelRequestRecorder()

    static var requestedHosts: [String] {
        recorder.values()
    }

    static func reset() {
        recorder.reset()
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let host = request.url?.host ?? ""
        Self.recorder.append(host)

        let status = host == "first.mock" ? 503 : 200
        let body: [String: Any] = status == 200
            ? ["choices": [["message": ["content": "Привет"]]]]
            : ["error": ["message": "unavailable"]]
        let data = try! JSONSerialization.data(withJSONObject: body)
        let response = HTTPURLResponse(
            url: request.url!, statusCode: status, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private final class ModelRequestRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var models: [String] = []

    func append(_ model: String) {
        lock.lock()
        models.append(model)
        lock.unlock()
    }

    func values() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return models
    }

    func reset() {
        lock.lock()
        models = []
        lock.unlock()
    }
}
