import XCTest

@testable import LiveEnglish

final class UpdateCheckerTests: XCTestCase {
    func testCompareEqualWithLeadingV() {
        XCTAssertEqual(UpdateChecker.compare(local: "0.1.0", remoteTag: "v0.1.0"), .notNewer)
        XCTAssertEqual(UpdateChecker.compare(local: "0.1.0", remoteTag: "V0.1.0"), .notNewer)
        XCTAssertEqual(UpdateChecker.compare(local: "0.1.0", remoteTag: "0.1.0"), .notNewer)
    }

    func testCompareRemoteNewer() {
        XCTAssertEqual(UpdateChecker.compare(local: "0.1.9", remoteTag: "0.2.0"), .remoteNewer)
        XCTAssertEqual(UpdateChecker.compare(local: "0.1.0", remoteTag: "v0.1.1"), .remoteNewer)
        XCTAssertEqual(UpdateChecker.compare(local: "0.1", remoteTag: "0.1.1"), .remoteNewer)
    }

    func testCompareRemoteLowerOrEqual() {
        XCTAssertEqual(UpdateChecker.compare(local: "0.2.0", remoteTag: "0.1.9"), .notNewer)
        XCTAssertEqual(UpdateChecker.compare(local: "0.1.1", remoteTag: "0.1"), .notNewer)
    }

    func testCompareUnparseable() {
        XCTAssertEqual(UpdateChecker.compare(local: "0.1.0", remoteTag: "nightly"), .unparseable)
        XCTAssertEqual(UpdateChecker.compare(local: "", remoteTag: "0.1.0"), .unparseable)
        XCTAssertEqual(UpdateChecker.compare(local: "0.1.0", remoteTag: ""), .unparseable)
    }

    func testRequestUsesGitHubLatestAndUserAgent() async {
        let captured = LockIsolated<URLRequest?>(nil)
        let checker = UpdateChecker(currentVersion: "0.1.0") { request in
            captured.set(request)
            throw URLError(.notConnectedToInternet)
        }
        _ = await checker.check()
        XCTAssertEqual(captured.value?.url, UpdateChecker.latestReleaseURL)
        XCTAssertEqual(captured.value?.httpMethod, "GET")
        XCTAssertEqual(captured.value?.value(forHTTPHeaderField: "User-Agent"), UpdateChecker.userAgent)
    }

    func testEmptyLocalVersionFailsWithoutFetch() async {
        let fetched = LockIsolated(false)
        let checker = UpdateChecker(currentVersion: "  ") { _ in
            fetched.set(true)
            throw URLError(.timedOut)
        }
        let result = await checker.check()
        XCTAssertEqual(result, .failed)
        XCTAssertFalse(fetched.value)
    }

    func testNewerPayloadReturnsReleaseURL() async {
        let html = "https://github.com/krisir/floattrans/releases/tag/v0.2.0"
        let checker = UpdateChecker(currentVersion: "0.1.0") { _ in
            githubOK(tag: "v0.2.0", html: html)
        }
        let result = await checker.check()
        XCTAssertEqual(result, .newer(URL(string: html)!))
        XCTAssertEqual(result.statusAfterCheck, .idle)
        XCTAssertEqual(result.urlToOpen, URL(string: html))
    }

    func testSameVersionIsUpToDateAndDoesNotOpen() async {
        let checker = UpdateChecker(currentVersion: "0.1.0") { _ in
            githubOK(tag: "v0.1.0", html: "https://github.com/krisir/floattrans/releases/tag/v0.1.0")
        }
        let result = await checker.check()
        XCTAssertEqual(result, .upToDate)
        XCTAssertNil(result.urlToOpen)
        XCTAssertEqual(result.statusAfterCheck, .upToDate)
    }

    func testLowerRemoteIsUpToDate() async {
        let checker = UpdateChecker(currentVersion: "0.2.0") { _ in
            githubOK(tag: "0.1.9", html: "https://github.com/krisir/floattrans/releases/tag/v0.1.9")
        }
        let result = await checker.check()
        XCTAssertEqual(result, .upToDate)
    }

    func testNetworkErrorIsFailed() async {
        let checker = UpdateChecker(currentVersion: "0.1.0") { _ in
            throw URLError(.notConnectedToInternet)
        }
        let result = await checker.check()
        XCTAssertEqual(result, .failed)
        XCTAssertNil(result.urlToOpen)
        XCTAssertEqual(result.statusAfterCheck, .failed)
    }

    func testHTTPFailuresAreFailed() async {
        for code in [403, 404, 429] {
            let checker = UpdateChecker(currentVersion: "0.1.0") { _ in
                githubHTTP(code, body: "{\"message\":\"no\"}")
            }
            let result = await checker.check()
            XCTAssertEqual(result, .failed, "status \(code) should fail")
            XCTAssertNil(result.urlToOpen)
        }
    }

    func testInvalidJSONIsFailed() async {
        let checker = UpdateChecker(currentVersion: "0.1.0") { _ in
            githubHTTP(200, body: "not-json")
        }
        let result = await checker.check()
        XCTAssertEqual(result, .failed)
    }

    func testNonNumericTagIsFailed() async {
        let checker = UpdateChecker(currentVersion: "0.1.0") { _ in
            githubOK(tag: "nightly", html: "https://github.com/krisir/floattrans/releases/tag/nightly")
        }
        let result = await checker.check()
        XCTAssertEqual(result, .failed)
    }

    func testMissingReleaseFieldsAreFailed() async {
        let checker = UpdateChecker(currentVersion: "0.1.0") { _ in
            githubHTTP(200, body: "{}")
        }
        let result = await checker.check()
        XCTAssertEqual(result, .failed)
    }
}

private final class LockIsolated<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: Value

    init(_ value: Value) {
        stored = value
    }

    var value: Value {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }

    func set(_ value: Value) {
        lock.lock()
        stored = value
        lock.unlock()
    }
}

private func githubOK(tag: String, html: String) -> (Data, URLResponse) {
    githubHTTP(200, body: "{\"tag_name\":\"\(tag)\",\"html_url\":\"\(html)\"}")
}

private func githubHTTP(_ status: Int, body: String) -> (Data, URLResponse) {
    let response = HTTPURLResponse(
        url: UpdateChecker.latestReleaseURL, statusCode: status, httpVersion: nil, headerFields: nil)!
    return (Data(body.utf8), response)
}
