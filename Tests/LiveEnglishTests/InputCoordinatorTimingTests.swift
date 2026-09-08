import XCTest

@testable import LiveEnglish

@MainActor
final class InputCoordinatorTimingTests: XCTestCase {
    private func snapshot(_ text: String) -> TextSnapshot {
        TextSnapshot(
            pid: 1, bundleIdentifier: "test.input", text: text,
            selectedRange: NSRange(location: (text as NSString).length, length: 0))
    }

    func testPauseModeTranslatesIncompleteAfterDelay() async {
        let input = InputCoordinator()
        input.timing = .pause
        input.delayMilliseconds = 20
        let session = InputSessionID(pid: 1)
        var received: String?
        input.onSentence = { text, _, _, _, _ in received = text }
        input.handle(snapshot("我今天会晚一点"), session: session, screen: nil)
        XCTAssertNil(received)
        try? await Task.sleep(for: .milliseconds(80))
        XCTAssertEqual(received, "我今天会晚一点")
    }

    func testCompleteSentenceIgnoresIncompleteFragment() async {
        let input = InputCoordinator()
        input.timing = .completeSentence
        input.delayMilliseconds = 20
        let session = InputSessionID(pid: 1)
        var received: String?
        input.onSentence = { text, _, _, _, _ in received = text }
        input.handle(snapshot("我今天会晚一点"), session: session, screen: nil)
        XCTAssertNil(received)
        try? await Task.sleep(for: .milliseconds(80))
        XCTAssertNil(received)
    }

    func testCompleteSentenceTranslatesPunctuatedSentenceImmediately() {
        let input = InputCoordinator()
        input.timing = .completeSentence
        input.delayMilliseconds = 200
        let session = InputSessionID(pid: 1)
        var received: String?
        input.onSentence = { text, _, _, _, _ in received = text }
        input.handle(snapshot("我今天会晚一点。"), session: session, screen: nil)
        XCTAssertEqual(received, "我今天会晚一点。")
    }

    func testShortcutModeDoesNotTranslateFromTyping() async {
        let input = InputCoordinator()
        input.timing = .shortcut
        input.delayMilliseconds = 20
        let session = InputSessionID(pid: 1)
        var received: String?
        input.onSentence = { text, _, _, _, _ in received = text }
        input.handle(snapshot("我今天会晚一点。"), session: session, screen: nil)
        try? await Task.sleep(for: .milliseconds(80))
        XCTAssertNil(received)
        input.translateNow(snapshot("我今天会晚一点。"), session: session, screen: nil)
        XCTAssertEqual(received, "我今天会晚一点。")
    }

    func testShortcutTranslateNowUsesLastGoodWhenLiveTextIsEmpty() {
        let live = TextSnapshot(
            pid: 1, bundleIdentifier: "test.input", text: "",
            selectedRange: NSRange(location: 0, length: 0))
        let recovered = ShortcutSnapshotRecovery.resolve(live: live, lastGoodText: "我今天会晚一点。")
        XCTAssertEqual(SentenceExtractor().extract(from: recovered), "我今天会晚一点。")

        let input = InputCoordinator()
        input.timing = .shortcut
        let session = InputSessionID(pid: 1)
        var received: String?
        input.onSentence = { text, _, _, _, _ in received = text }
        input.translateNow(live, session: session, screen: nil)
        XCTAssertNil(received)
        input.translateNow(recovered, session: session, screen: nil)
        XCTAssertEqual(received, "我今天会晚一点。")
    }
}
