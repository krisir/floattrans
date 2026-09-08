import Foundation

enum UpdateCheckResult: Equatable, Sendable {
    case newer(URL)
    case upToDate
    case failed

    var urlToOpen: URL? {
        if case .newer(let url) = self { return url }
        return nil
    }

    var statusAfterCheck: UpdateCheckStatus {
        switch self {
        case .newer: return .idle
        case .upToDate: return .upToDate
        case .failed: return .failed
        }
    }
}

enum UpdateCheckStatus: Equatable, Sendable {
    case idle
    case checking
    case upToDate
    case failed
}

enum VersionCompareResult: Equatable, Sendable {
    case remoteNewer
    case notNewer
    case unparseable
}

struct GitHubLatestRelease: Decodable, Sendable {
    let tagName: String
    let htmlURL: String

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}

struct UpdateChecker: Sendable {
    static let latestReleaseURL = URL(string: "https://api.github.com/repos/krisir/floattrans/releases/latest")!
    static let userAgent = "FloatTrans (https://github.com/krisir/floattrans)"

    var currentVersion: String
    var fetch: @Sendable (URLRequest) async throws -> (Data, URLResponse)

    init(
        currentVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "",
        fetch: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse) = { request in
            try await URLSession.shared.data(for: request)
        }
    ) {
        self.currentVersion = currentVersion
        self.fetch = fetch
    }

    func check() async -> UpdateCheckResult {
        let local = currentVersion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !local.isEmpty else { return .failed }

        var request = URLRequest(url: Self.latestReleaseURL)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.httpMethod = "GET"

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await fetch(request)
        } catch {
            return .failed
        }

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            return .failed
        }

        let release: GitHubLatestRelease
        do {
            release = try JSONDecoder().decode(GitHubLatestRelease.self, from: data)
        } catch {
            return .failed
        }

        let tag = release.tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        let html = release.htmlURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tag.isEmpty, let url = URL(string: html), url.scheme == "https" || url.scheme == "http" else {
            return .failed
        }

        switch Self.compare(local: local, remoteTag: tag) {
        case .remoteNewer:
            return .newer(url)
        case .notNewer:
            return .upToDate
        case .unparseable:
            return .failed
        }
    }

    static func compare(local: String, remoteTag: String) -> VersionCompareResult {
        guard let localParts = dottedIntegers(local), let remoteParts = dottedIntegers(remoteTag) else {
            return .unparseable
        }
        let count = max(localParts.count, remoteParts.count)
        for index in 0..<count {
            let localValue = index < localParts.count ? localParts[index] : 0
            let remoteValue = index < remoteParts.count ? remoteParts[index] : 0
            if remoteValue > localValue { return .remoteNewer }
            if remoteValue < localValue { return .notNewer }
        }
        return .notNewer
    }

    static func stripLeadingV(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first, first == "v" || first == "V" else { return trimmed }
        return String(trimmed.dropFirst())
    }

    private static func dottedIntegers(_ raw: String) -> [Int]? {
        let stripped = stripLeadingV(raw)
        guard !stripped.isEmpty else { return nil }
        var values: [Int] = []
        for part in stripped.split(separator: ".", omittingEmptySubsequences: false) {
            guard !part.isEmpty, part.allSatisfy(\.isNumber), part.unicodeScalars.allSatisfy({ $0.isASCII }),
                let value = Int(part)
            else {
                return nil
            }
            values.append(value)
        }
        return values
    }
}
