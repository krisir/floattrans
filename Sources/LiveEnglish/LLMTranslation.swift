import Foundation

/// The wire protocol used by a language-model endpoint.
///
/// DeepSeek, GLM and most OpenAI-compatible gateways use the chat-completions
/// protocol. Claude uses Anthropic's messages protocol.
public enum LLMProvider: String, Codable, CaseIterable, Identifiable, Sendable, Hashable {
    case openAICompatible = "openai-compatible"
    case anthropic
    case deepSeek = "deepseek"
    case glm
    case custom

    public var id: String { rawValue }

    /// A short label suitable for a settings picker.
    public var displayName: String {
        switch self {
        case .openAICompatible: return "OpenAI compatible"
        case .anthropic: return "Claude (Anthropic)"
        case .deepSeek: return "DeepSeek"
        case .glm: return "GLM (智谱)"
        case .custom: return "Custom"
        }
    }

    /// Common defaults shown when adding a model. Users can still override
    /// the URL for regional gateways, proxies, or a local Ollama-compatible
    /// server.
    public var defaultBaseURL: String {
        switch self {
        case .openAICompatible: return "https://api.openai.com/v1"
        case .anthropic: return "https://api.anthropic.com/v1"
        case .deepSeek: return "https://api.deepseek.com/v1"
        case .glm: return "https://open.bigmodel.cn/api/paas/v4"
        case .custom: return "https://"
        }
    }

    public var defaultModel: String {
        switch self {
        case .openAICompatible: return "gpt-4.1-mini"
        case .anthropic: return "claude-3-5-haiku-latest"
        case .deepSeek: return "deepseek-chat"
        case .glm: return "glm-4-flash"
        case .custom: return ""
        }
    }

    /// Convenient aliases for callers that do not need to distinguish a
    /// named OpenAI-compatible service from the generic protocol.
    public static var openAI: LLMProvider { .openAICompatible }
    public static var openai: LLMProvider { .openAICompatible }
    public static var claude: LLMProvider { .anthropic }
    public static var deepseek: LLMProvider { .deepSeek }
    public static var zhipu: LLMProvider { .glm }
    public static var customProvider: LLMProvider { .custom }

    fileprivate var isAnthropic: Bool { self == .anthropic }
    fileprivate var supportsReasoningEffort: Bool { self == .openAICompatible }

    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self).lowercased()
        switch value {
        case "openai", "open-ai", "openai-compatible", "open_ai_compatible": self = .openAICompatible
        case "anthropic", "claude": self = .anthropic
        case "deepseek", "deep-seek", "deep_seek": self = .deepSeek
        case "glm", "zhipu", "chatglm": self = .glm
        case "custom", "other": self = .custom
        default:
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(), debugDescription: "Unknown LLM provider \(value)")
        }
    }
}

/// Controls whether the provider should spend extra tokens on reasoning.
/// Providers that expose their own reasoning model (for example
/// `deepseek-reasoner`) can still be selected by changing `model`; the named
/// DeepSeek/GLM providers intentionally do not send an unknown
/// `reasoning_effort` field.
public enum LLMThinkingMode: String, Codable, CaseIterable, Identifiable, Sendable, Hashable {
    case automatic
    case nonThinking = "non-thinking"
    case thinking

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .automatic: return "Automatic"
        case .nonThinking: return "Non-thinking"
        case .thinking: return "Thinking"
        }
    }

    public static var off: LLMThinkingMode { .nonThinking }
    public static var on: LLMThinkingMode { .thinking }

    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self).lowercased()
        switch value {
        case "automatic", "auto": self = .automatic
        case "non-thinking", "nonthinking", "off", "none", "disabled": self = .nonThinking
        case "thinking", "on", "enabled": self = .thinking
        default:
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(), debugDescription: "Unknown thinking mode \(value)")
        }
    }
}

/// A single ordered model entry. The array passed to `LLMModelRouter` is the
/// failover order used at runtime; no additional priority field is needed.
public struct LLMModelConfiguration: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var provider: LLMProvider
    /// A base URL or a complete endpoint URL. The router appends the protocol
    /// path when needed (`/chat/completions` or `/v1/messages`).
    public var baseURL: String
    /// Keep this value in the Keychain when persisting settings. It remains on
    /// the value type as a convenience for the request engine and for local
    /// endpoints that do not need authentication.
    public var apiKey: String
    public var model: String
    public var systemPrompt: String
    public var thinking: LLMThinkingMode
    public var enabled: Bool
    /// Per-model request/failover timeout in seconds. Values less than or
    /// equal to zero use the router's default timeout.
    public var timeoutSeconds: Double

    /// Naming aliases keep the model convenient to bind from SwiftUI forms.
    public var thinkingMode: LLMThinkingMode {
        get { thinking }
        set { thinking = newValue }
    }

    /// Boolean bridge for simple toggle controls. `automatic` maps to false
    /// when read; callers that need the three-state behavior should use
    /// `thinkingMode`.
    public var isThinking: Bool {
        get { thinking == .thinking }
        set { thinking = newValue ? .thinking : .nonThinking }
    }

    public var endpointURL: URL? { URL(string: baseURL.trimmingCharacters(in: .whitespacesAndNewlines)) }

    public init(
        id: UUID = UUID(),
        name: String,
        provider: LLMProvider = .openAICompatible,
        baseURL: String,
        apiKey: String = "",
        model: String,
        systemPrompt: String = "",
        thinking: LLMThinkingMode = .automatic,
        enabled: Bool = true,
        timeoutSeconds: Double = 8
    ) {
        self.id = id
        self.name = name
        self.provider = provider
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.model = model
        self.systemPrompt = systemPrompt
        self.thinking = thinking
        self.enabled = enabled
        self.timeoutSeconds = timeoutSeconds
    }

    /// Boolean-thinking convenience initializer for settings migrations and
    /// clients that expose only an on/off switch.
    public init(
        id: UUID = UUID(),
        name: String,
        provider: LLMProvider = .openAICompatible,
        baseURL: String,
        apiKey: String = "",
        model: String,
        systemPrompt: String = "",
        thinking: Bool,
        enabled: Bool = true,
        timeoutSeconds: Double = 8
    ) {
        self.init(
            id: id,
            name: name,
            provider: provider,
            baseURL: baseURL,
            apiKey: apiKey,
            model: model,
            systemPrompt: systemPrompt,
            thinking: thinking ? .thinking : .nonThinking,
            enabled: enabled,
            timeoutSeconds: timeoutSeconds)
    }

    /// URL-labelled convenience initializer for callers that already parsed
    /// and validated the endpoint.
    public init(
        id: UUID = UUID(),
        name: String,
        provider: LLMProvider = .openAICompatible,
        baseURL: URL,
        apiKey: String = "",
        model: String,
        systemPrompt: String = "",
        thinking: LLMThinkingMode = .automatic,
        enabled: Bool = true,
        timeoutSeconds: Double = 8
    ) {
        self.init(
            id: id,
            name: name,
            provider: provider,
            baseURL: baseURL.absoluteString,
            apiKey: apiKey,
            model: model,
            systemPrompt: systemPrompt,
            thinking: thinking,
            enabled: enabled,
            timeoutSeconds: timeoutSeconds
        )
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, provider, baseURL, apiKey, model, systemPrompt, thinking, enabled, timeoutSeconds
    }

    /// Decoding is deliberately lenient so settings written by an older build
    /// (before `thinking`, `enabled`, or `timeoutSeconds` existed) continue to
    /// work after an upgrade.
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try values.decodeIfPresent(String.self, forKey: .name) ?? "Model"
        provider = try values.decodeIfPresent(LLMProvider.self, forKey: .provider) ?? .openAICompatible
        baseURL = try values.decodeIfPresent(String.self, forKey: .baseURL) ?? ""
        apiKey = try values.decodeIfPresent(String.self, forKey: .apiKey) ?? ""
        model = try values.decodeIfPresent(String.self, forKey: .model) ?? ""
        systemPrompt = try values.decodeIfPresent(String.self, forKey: .systemPrompt) ?? ""
        thinking = try values.decodeIfPresent(LLMThinkingMode.self, forKey: .thinking) ?? .automatic
        enabled = try values.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        timeoutSeconds = try values.decodeIfPresent(Double.self, forKey: .timeoutSeconds) ?? 8
    }
}

/// A failure associated with one model attempt. This is useful for diagnostics
/// while keeping the public error Sendable and easy to display in a menu bar UI.
public struct LLMModelFailure: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let modelName: String
    public let message: String

    public init(id: UUID, modelName: String, message: String) {
        self.id = id
        self.modelName = modelName
        self.message = message
    }
}

public enum LLMTranslationError: Error, Equatable, LocalizedError, Sendable {
    case emptyText
    case noEnabledModels
    case invalidEndpoint(model: String, value: String)
    case timeout(model: String, seconds: Double)
    case httpStatus(model: String, statusCode: Int, message: String)
    case invalidResponse(model: String, message: String)
    case allModelsFailed([LLMModelFailure])

    public var errorDescription: String? {
        switch self {
        case .emptyText:
            return "There is no text to translate."
        case .noEnabledModels:
            return "No enabled language model is configured."
        case let .invalidEndpoint(model, value):
            return "The endpoint for \(model) is invalid: \(value)"
        case let .timeout(model, seconds):
            return "\(model) did not respond within \(Self.format(seconds)) seconds."
        case let .httpStatus(model, statusCode, message):
            return "\(model) returned HTTP \(statusCode): \(message)"
        case let .invalidResponse(model, message):
            return "\(model) returned an invalid response: \(message)"
        case let .allModelsFailed(failures):
            if failures.isEmpty { return "All language models failed." }
            let details = failures.map { "\($0.modelName): \($0.message)" }.joined(separator: "; ")
            return "All language models failed. \(details)"
        }
    }

    private static func format(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value)
    }
}

/// An ordered, actor-isolated LLM translation engine. Requests are attempted
/// in array order; a timeout, transport error, malformed response, or HTTP
/// error advances to the next enabled model. Cancellation from the caller is
/// propagated immediately so a newer sentence can supersede an old one.
public actor LLMModelRouter: TranslationEngine {
    private var configurations: [LLMModelConfiguration]
    private var defaultTimeoutSeconds: Double
    private let session: URLSession

    public init(
        models: [LLMModelConfiguration] = [],
        timeoutSeconds: Double = 8,
        session: URLSession = .shared
    ) {
        configurations = models
        defaultTimeoutSeconds = Self.clampTimeout(timeoutSeconds)
        self.session = session
    }

    /// Alternate label useful when wiring the value to a settings store.
    public init(
        configurations: [LLMModelConfiguration],
        fallbackTimeoutSeconds: Double = 8,
        session: URLSession = .shared
    ) {
        self.init(models: configurations, timeoutSeconds: fallbackTimeoutSeconds, session: session)
    }

    public func modelConfigurations() -> [LLMModelConfiguration] { configurations }

    public var fallbackTimeoutSeconds: Double {
        get { defaultTimeoutSeconds }
        set { defaultTimeoutSeconds = Self.clampTimeout(newValue) }
    }

    public func setModels(_ models: [LLMModelConfiguration]) { configurations = models }

    public func replaceModels(_ models: [LLMModelConfiguration]) { configurations = models }

    public func setFallbackTimeout(_ seconds: Double) {
        defaultTimeoutSeconds = Self.clampTimeout(seconds)
    }

    public func fallbackTimeout() -> Double { defaultTimeoutSeconds }

    public func translate(_ text: String, from source: Language, to target: Language) async throws -> String {
        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { throw LLMTranslationError.emptyText }
        if source == target { return input }

        let enabledModels = configurations.filter(\.enabled)
        guard !enabledModels.isEmpty else { throw LLMTranslationError.noEnabledModels }

        var failures: [LLMModelFailure] = []
        for configuration in enabledModels {
            try Task.checkCancellation()
            do {
                let timeout = configuration.timeoutSeconds > 0
                    ? Self.clampTimeout(configuration.timeoutSeconds)
                    : defaultTimeoutSeconds
                let result = try await withTimeout(timeout, modelName: configuration.name) {
                    try await self.request(input, from: source, to: target, configuration: configuration)
                }
                try Task.checkCancellation()
                return result
            } catch is CancellationError {
                throw CancellationError()
            } catch let error as LLMTranslationError {
                failures.append(
                    LLMModelFailure(
                        id: configuration.id,
                        modelName: configuration.name,
                        message: error.errorDescription ?? String(describing: error)))
            } catch {
                failures.append(
                    LLMModelFailure(
                        id: configuration.id,
                        modelName: configuration.name,
                        message: error.localizedDescription))
            }
        }
        throw LLMTranslationError.allModelsFailed(failures)
    }

    private func request(
        _ text: String,
        from source: Language,
        to target: Language,
        configuration: LLMModelConfiguration
    ) async throws -> String {
        let endpoint = try Self.endpointURL(for: configuration)
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        // URLSession's own timeout complements the task-group race below. It
        // ensures a stalled DNS/TLS/body task is cancelled even when a custom
        // URLProtocol or a proxy does not react immediately to cancellation.
        request.timeoutInterval = configuration.timeoutSeconds > 0
            ? Self.clampTimeout(configuration.timeoutSeconds)
            : defaultTimeoutSeconds
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let apiKey = configuration.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if configuration.provider.isAnthropic {
            if !apiKey.isEmpty {
                request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            }
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.httpBody = try Self.encodeClaudeRequest(
                text: text, source: source, target: target, configuration: configuration)
        } else {
            if !apiKey.isEmpty {
                let authorization = apiKey.lowercased().hasPrefix("bearer ") ? apiKey : "Bearer \(apiKey)"
                request.setValue(authorization, forHTTPHeaderField: "Authorization")
            }
            request.httpBody = try Self.encodeOpenAIRequest(
                text: text, source: source, target: target, configuration: configuration)
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMTranslationError.invalidResponse(model: configuration.name, message: "Missing HTTP response")
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = Self.errorMessage(from: data) ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            throw LLMTranslationError.httpStatus(
                model: configuration.name, statusCode: httpResponse.statusCode, message: message)
        }

        let translated: String
        do {
            translated = configuration.provider.isAnthropic
                ? try Self.decodeClaudeResponse(data)
                : try Self.decodeOpenAIResponse(data)
        } catch let error as LLMTranslationError {
            throw error
        } catch {
            throw LLMTranslationError.invalidResponse(model: configuration.name, message: error.localizedDescription)
        }
        let value = translated.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            throw LLMTranslationError.invalidResponse(model: configuration.name, message: "Empty translation")
        }
        return value
    }

    private func withTimeout<T: Sendable>(
        _ seconds: Double,
        modelName: String,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                let nanoseconds = UInt64(max(0, seconds) * 1_000_000_000)
                try await Task.sleep(nanoseconds: nanoseconds)
                throw LLMTranslationError.timeout(model: modelName, seconds: seconds)
            }
            defer { group.cancelAll() }
            guard let result = try await group.next() else {
                throw LLMTranslationError.timeout(model: modelName, seconds: seconds)
            }
            return result
        }
    }

    private static func clampTimeout(_ value: Double) -> Double {
        guard value.isFinite else { return 8 }
        // Keep a very small lower bound for deterministic tests and local
        // endpoints; the settings UI can expose a friendlier 1–300 s range.
        return min(max(value, 0.01), 300)
    }
}

/// Name retained for callers that prefer to refer to the engine rather than
/// the routing implementation. It is an actor and conforms to
/// `TranslationEngine` through `LLMModelRouter`.
public typealias LLMTranslationEngine = LLMModelRouter

private extension LLMModelRouter {
    struct ChatMessage: Encodable {
        let role: String
        let content: String
    }

    struct OpenAIRequest: Encodable {
        let model: String
        let messages: [ChatMessage]
        let stream: Bool
        let reasoning_effort: String?

        private enum CodingKeys: String, CodingKey { case model, messages, stream, reasoning_effort }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(model, forKey: .model)
            try container.encode(messages, forKey: .messages)
            try container.encode(stream, forKey: .stream)
            try container.encodeIfPresent(reasoning_effort, forKey: .reasoning_effort)
        }
    }

    struct ClaudeRequest: Encodable {
        let model: String
        let max_tokens: Int
        let system: String?
        let messages: [ChatMessage]
        let thinking: ClaudeThinking?

        private enum CodingKeys: String, CodingKey { case model, max_tokens, system, messages, thinking }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(model, forKey: .model)
            try container.encode(max_tokens, forKey: .max_tokens)
            try container.encodeIfPresent(system, forKey: .system)
            try container.encode(messages, forKey: .messages)
            try container.encodeIfPresent(thinking, forKey: .thinking)
        }
    }

    struct ClaudeThinking: Encodable {
        let type: String
        let budget_tokens: Int
    }

    struct OpenAIResponse: Decodable {
        let choices: [OpenAIChoice]?
    }

    struct OpenAIChoice: Decodable {
        let message: OpenAIMessage?
        let text: String?
    }

    struct OpenAIMessage: Decodable {
        let content: FlexibleContent?
    }

    enum FlexibleContent: Decodable {
        case string(String)
        case parts([TextPart])
        case none

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() {
                self = .none
            } else if let value = try? container.decode(String.self) {
                self = .string(value)
            } else if let value = try? container.decode([TextPart].self) {
                self = .parts(value)
            } else {
                throw DecodingError.dataCorruptedError(
                    in: container, debugDescription: "Unsupported message content")
            }
        }

        var text: String {
            switch self {
            case let .string(value): return value
            case let .parts(parts): return parts.compactMap(\.text).joined()
            case .none: return ""
            }
        }
    }

    struct TextPart: Decodable {
        let type: String?
        let text: String?
    }

    struct ClaudeResponse: Decodable {
        let content: [ClaudeContent]?
    }

    struct ClaudeContent: Decodable {
        let type: String?
        let text: String?
    }

    struct ErrorEnvelope: Decodable {
        let error: ErrorObject?
    }

    struct ErrorObject: Decodable {
        let message: String?
        let type: String?
        let code: String?
    }

    static func endpointURL(for configuration: LLMModelConfiguration) throws -> URL {
        let raw = configuration.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: raw),
            let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme),
            components.host?.isEmpty == false
        else {
            throw LLMTranslationError.invalidEndpoint(model: configuration.name, value: configuration.baseURL)
        }

        var path = components.path
        while path.count > 1, path.hasSuffix("/") { path.removeLast() }
        if configuration.provider.isAnthropic {
            if !path.lowercased().hasSuffix("/messages") {
                if path.isEmpty || path == "/" {
                    path = "/v1/messages"
                } else if path.lowercased().hasSuffix("/v1") {
                    path += "/messages"
                } else {
                    path += "/v1/messages"
                }
            }
        } else if !path.lowercased().hasSuffix("/chat/completions") {
            if path.isEmpty || path == "/" {
                path = "/chat/completions"
            } else {
                path += "/chat/completions"
            }
        }
        components.path = path
        guard let url = components.url else {
            throw LLMTranslationError.invalidEndpoint(model: configuration.name, value: configuration.baseURL)
        }
        return url
    }

    static func encodeOpenAIRequest(
        text: String,
        source: Language,
        target: Language,
        configuration: LLMModelConfiguration
    ) throws -> Data {
        let prompt = translationPrompt(text: text, source: source, target: target)
        let system = configuration.systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let messages = [
            ChatMessage(role: "system", content: system.isEmpty ? defaultSystemPrompt : system),
            ChatMessage(role: "user", content: prompt),
        ]
        let effort: String?
        if configuration.provider.supportsReasoningEffort {
            switch configuration.thinking {
            case .automatic: effort = nil
            case .nonThinking: effort = "none"
            case .thinking: effort = "high"
            }
        } else {
            effort = nil
        }
        return try JSONEncoder().encode(
            OpenAIRequest(model: configuration.model, messages: messages, stream: false, reasoning_effort: effort))
    }

    static func encodeClaudeRequest(
        text: String,
        source: Language,
        target: Language,
        configuration: LLMModelConfiguration
    ) throws -> Data {
        let prompt = translationPrompt(text: text, source: source, target: target)
        let system = configuration.systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let thinking: ClaudeThinking? = configuration.thinking == .thinking
            ? ClaudeThinking(type: "enabled", budget_tokens: 1024)
            : nil
        return try JSONEncoder().encode(
            ClaudeRequest(
                model: configuration.model,
                max_tokens: 2048,
                system: system.isEmpty ? defaultSystemPrompt : system,
                messages: [ChatMessage(role: "user", content: prompt)],
                thinking: thinking))
    }

    static func decodeOpenAIResponse(_ data: Data) throws -> String {
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let choice = response.choices?.first else {
            throw LLMTranslationError.invalidResponse(model: "LLM", message: "Missing choices")
        }
        let content = choice.message?.content?.text ?? choice.text ?? ""
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LLMTranslationError.invalidResponse(model: "LLM", message: "Missing message content")
        }
        return content
    }

    static func decodeClaudeResponse(_ data: Data) throws -> String {
        let response = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        let text = response.content?.filter { $0.type == "text" || $0.type == nil }
            .compactMap(\.text).joined() ?? ""
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LLMTranslationError.invalidResponse(model: "Claude", message: "Missing text content")
        }
        return text
    }

    static func errorMessage(from data: Data) -> String? {
        if let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data),
            let message = envelope.error?.message, !message.isEmpty
        {
            return message
        }
        guard let body = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines), !body.isEmpty
        else { return nil }
        return String(body.prefix(500))
    }

    static let defaultSystemPrompt =
        "You are a professional translator. Preserve the meaning, tone, and formatting. Return only the translation, with no explanation."

    static func translationPrompt(text: String, source: Language, target: Language) -> String {
        "Translate the following text from \(languageName(source)) to \(languageName(target)). Return only the translated text.\n\n\(text)"
    }

    static func languageName(_ language: Language) -> String {
        // `Language` exposes a stable English label; using it here means newly
        // added language cases automatically appear in the LLM prompt.
        return language.englishName
    }
}
