import Foundation
import Security

/// Errors returned by ``KeychainStore``.
///
/// The error deliberately contains only the Keychain status code (never the
/// account name or secret) so it can safely be passed to diagnostics/UI.
public enum KeychainStoreError: Error, Equatable, LocalizedError, Sendable {
    case invalidService
    case invalidAccount
    case unexpectedStatus(Int32)
    case invalidData

    public var errorDescription: String? {
        switch self {
        case .invalidService:
            return "The Keychain service name is invalid."
        case .invalidAccount:
            return "The Keychain account name is invalid."
        case let .unexpectedStatus(status):
            // Keep this numeric: Security.framework's human-readable status
            // is not guaranteed to be stable and must not include a secret.
            return "Keychain operation failed (status \(status))."
        case .invalidData:
            return "The Keychain item contains invalid data."
        }
    }
}

/// A small, synchronous wrapper around macOS Keychain generic-password
/// items. API keys should be stored here instead of in UserDefaults or a
/// Codable settings blob.
///
/// The wrapper is a value type and does not retain secret data. Each method
/// talks to Security.framework directly, which also keeps the API usable from
/// a ``@MainActor`` settings store without introducing an additional actor.
public struct KeychainStore: Sendable {
    /// The app's bundle identifier is used in production. The fallback keeps
    /// command-line/unit-test invocations deterministic when no bundle exists.
    public static let defaultService = "cc.kristar.floattrans"

    public let service: String
    public let accessGroup: String?

    public init(service: String = KeychainStore.defaultService, accessGroup: String? = nil) {
        self.service = service
        let group = accessGroup?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.accessGroup = group?.isEmpty == true ? nil : group
    }

    /// Stores (or replaces) a UTF-8 string for an account.
    public func set(_ value: String, for account: String) throws {
        try validate()
        let account = try normalizedAccount(account)
        let data = Data(value.utf8)

        var query = baseQuery(account: account)
        let updateAttributes: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else {
            throw KeychainStoreError.unexpectedStatus(updateStatus)
        }

        query[kSecValueData as String] = data
        // This item is intentionally not synchronizable: API keys should not
        // be copied to another device through iCloud Keychain by surprise.
        query[kSecAttrSynchronizable as String] = kCFBooleanFalse as Any
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        if addStatus == errSecSuccess { return }

        // Another writer may have inserted the item between Update and Add.
        // Retry the update once rather than surfacing a spurious duplicate.
        if addStatus == errSecDuplicateItem {
            let retryStatus = SecItemUpdate(baseQuery(account: account) as CFDictionary, updateAttributes as CFDictionary)
            if retryStatus == errSecSuccess { return }
            throw KeychainStoreError.unexpectedStatus(retryStatus)
        }
        throw KeychainStoreError.unexpectedStatus(addStatus)
    }

    /// Optional-value convenience. `nil` (or an empty value) removes the
    /// account, which makes clearing a password field straightforward.
    public func set(_ value: String?, for account: String) throws {
        guard let value, !value.isEmpty else {
            try remove(for: account)
            return
        }
        try set(value, for: account)
    }

    /// Reads a UTF-8 string, returning `nil` when no item exists.
    public func string(for account: String) throws -> String? {
        try validate()
        let account = try normalizedAccount(account)
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = kCFBooleanTrue as Any
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw KeychainStoreError.unexpectedStatus(status)
        }
        guard let data = result as? Data, let value = String(data: data, encoding: .utf8) else {
            throw KeychainStoreError.invalidData
        }
        return value
    }

    /// Alias useful to callers that prefer a `get` spelling.
    public func get(for account: String) throws -> String? {
        try string(for: account)
    }

    /// Removes a stored account. Removing a missing item is idempotent.
    public func remove(for account: String) throws {
        try validate()
        let account = try normalizedAccount(account)
        let status = SecItemDelete(baseQuery(account: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainStoreError.unexpectedStatus(status)
        }
    }

    /// Alias useful to callers that prefer a `delete` spelling.
    public func delete(for account: String) throws {
        try remove(for: account)
    }

    // MARK: Model API-key helpers

    /// Stable account namespace for a model configuration UUID.
    public static func account(forModelID id: UUID) -> String {
        "llm-api-key-\(id.uuidString.lowercased())"
    }

    public func setAPIKey(_ value: String?, forModelID id: UUID) throws {
        try set(value, for: Self.account(forModelID: id))
    }

    public func apiKey(forModelID id: UUID) throws -> String? {
        try string(for: Self.account(forModelID: id))
    }

    public func deleteAPIKey(forModelID id: UUID) throws {
        try remove(for: Self.account(forModelID: id))
    }

    /// Spelling aliases for settings code that uses `modelID:` labels.
    public func setAPIKey(_ value: String?, modelID: UUID) throws {
        try setAPIKey(value, forModelID: modelID)
    }

    public func apiKey(modelID: UUID) throws -> String? {
        try apiKey(forModelID: modelID)
    }

    public func deleteAPIKey(modelID: UUID) throws {
        try deleteAPIKey(forModelID: modelID)
    }
}

private extension KeychainStore {
    func validate() throws {
        guard !service.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw KeychainStoreError.invalidService
        }
    }

    func normalizedAccount(_ account: String) throws -> String {
        let value = account.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { throw KeychainStoreError.invalidAccount }
        return value
    }

    func baseQuery(account: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }
}

