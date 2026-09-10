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

    func testDeepSeekAndGLMEncodeTheirThinkingControls() async throws {
        let deepSeek = LLMModelConfiguration(
            name: "deepseek",
            provider: .deepSeek,
            baseURL: "https://deepseek.mock/v1",
            model: "deepseek-chat",
            thinking: .nonThinking)
        let glm = LLMModelConfiguration(
            name: "glm",
            provider: .glm,
            baseURL: "https://glm.mock/v4",
            model: "glm-4",
            thinking: .thinking)

        _ = try await router(for: [deepSeek]).translate("你好", from: .chinese, to: .english)
        _ = try await router(for: [glm]).translate("你好", from: .chinese, to: .english)

        let requests = MockLLMURLProtocol.requests
        XCTAssertEqual(requests[0].path, "/v1/chat/completions")
        XCTAssertEqual(requests[0].json["thinking"] as? [String: String], ["type": "disabled"])
        XCTAssertNil(requests[0].json["reasoning_effort"])
        XCTAssertEqual(requests[1].path, "/v4/chat/completions")
        XCTAssertEqual(requests[1].json["thinking"] as? [String: String], ["type": "enabled"])
    }

    func testOpenAIResponsesAndClaudeMessagesUseTheirOwnProtocol() async throws {
        let responses = LLMModelConfiguration(
            name: "responses",
            provider: .openAICompatible,
            apiProtocol: .responses,
            baseURL: "https://responses.mock/v1",
            apiKey: "test-openai-key",
            model: "gpt-5",
            thinking: .nonThinking)
        let claude = LLMModelConfiguration(
            name: "claude",
            provider: .anthropic,
            baseURL: "https://claude.mock/v1",
            apiKey: "test-claude-key",
            model: "claude-sonnet",
            thinking: .thinking)

        let responsesTranslation = try await router(for: [responses]).translate("Hello", from: .english, to: .russian)
        let claudeTranslation = try await router(for: [claude]).translate("Hello", from: .english, to: .russian)
        XCTAssertEqual(responsesTranslation, "Привет")
        XCTAssertEqual(claudeTranslation, "Привет")

        let requests = MockLLMURLProtocol.requests
        XCTAssertEqual(requests[0].path, "/v1/responses")
        XCTAssertEqual(requests[0].authorization, "Bearer test-openai-key")
        XCTAssertEqual(requests[0].json["reasoning"] as? [String: String], ["effort": "none"])
        XCTAssertEqual(requests[1].path, "/v1/messages")
        XCTAssertEqual(requests[1].anthropicAPIKey, "test-claude-key")
        let claudeThinking = try XCTUnwrap(requests[1].json["thinking"] as? [String: Any])
        XCTAssertEqual(claudeThinking["type"] as? String, "enabled")
        XCTAssertEqual(claudeThinking["budget_tokens"] as? Int, 1024)
    }

    func testClaudeNonThinkingOmitsExtendedThinkingObject() async throws {
        let claude = LLMModelConfiguration(
            name: "claude",
            provider: .anthropic,
            baseURL: "https://claude.mock/v1",
            model: "claude-sonnet",
            thinking: .nonThinking)

        _ = try await router(for: [claude]).translate("Hello", from: .english, to: .russian)

        XCTAssertNil(MockLLMURLProtocol.requests[0].json["thinking"])
    }

    private func router(for models: [LLMModelConfiguration]) -> LLMModelRouter {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockLLMURLProtocol.self]
        return LLMModelRouter(models: models, timeoutSeconds: 2, session: URLSession(configuration: configuration))
    }
}

private final class MockLLMURLProtocol: URLProtocol {
    private static let recorder = ModelRequestRecorder()

    static var requestedHosts: [String] {
        recorder.values()
    }

    static var requests: [RecordedRequest] {
        recorder.requests()
    }

    static func reset() {
        recorder.reset()
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let host = request.url?.host ?? ""
        Self.recorder.append(host, request: request)

        let status = host == "first.mock" ? 503 : 200
        let body: [String: Any]
        if status != 200 {
            body = ["error": ["message": "unavailable"]]
        } else if request.url?.path.hasSuffix("/responses") == true {
            body = ["output_text": "Привет"]
        } else if request.url?.path.hasSuffix("/messages") == true {
            body = ["content": [["type": "text", "text": "Привет"]]]
        } else {
            body = ["choices": [["message": ["content": "Привет"]]]]
        }
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
    private var capturedRequests: [RecordedRequest] = []

    func append(_ model: String, request: URLRequest? = nil) {
        lock.lock()
        models.append(model)
        if let request { capturedRequests.append(RecordedRequest(request: request)) }
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
        capturedRequests = []
        lock.unlock()
    }

    func requests() -> [RecordedRequest] {
        lock.lock()
        defer { lock.unlock() }
        return capturedRequests
    }
}

private struct RecordedRequest: @unchecked Sendable {
    let path: String
    let authorization: String?
    let anthropicAPIKey: String?
    let json: [String: Any]

    init(request: URLRequest) {
        path = request.url?.path ?? ""
        authorization = request.value(forHTTPHeaderField: "Authorization")
        anthropicAPIKey = request.value(forHTTPHeaderField: "x-api-key")
        if let parsed = try? JSONSerialization.jsonObject(with: Self.bodyData(from: request)) as? [String: Any]
        {
            json = parsed
        } else {
            json = [:]
        }
    }

    private static func bodyData(from request: URLRequest) -> Data {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return Data() }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4_096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }
}
