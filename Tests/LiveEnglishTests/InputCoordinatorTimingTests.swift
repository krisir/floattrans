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
        input.onSentence = { source, _, _, _, _, _, _ in received = source.text }
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
        input.onSentence = { source, _, _, _, _, _, _ in received = source.text }
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
        input.onSentence = { source, _, _, _, _, _, _ in received = source.text }
        input.handle(snapshot("我今天会晚一点。"), session: session, screen: nil)
        XCTAssertEqual(received, "我今天会晚一点。")
    }

    func testShortcutModeDoesNotTranslateFromTyping() async {
        let input = InputCoordinator()
        input.timing = .shortcut
        input.delayMilliseconds = 20
        let session = InputSessionID(pid: 1)
        var received: String?
        input.onSentence = { source, _, _, _, _, _, _ in received = source.text }
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
        input.onSentence = { source, _, _, _, _, _, _ in received = source.text }
        input.translateNow(live, session: session, screen: nil)
        XCTAssertNil(received)
        input.translateNow(recovered, session: session, screen: nil)
        XCTAssertEqual(received, "我今天会晚一点。")
    }

    func testCorrectionAfterDeletionAndRetypingIsASeparateRevision() {
        let input = InputCoordinator()
        input.timing = .completeSentence
        let session = InputSessionID(pid: 1)
        var received: [String] = []
        input.onSentence = { source, _, _, _, _, _, _ in received.append(source.text) }

        input.handle(snapshot("我今天会晚一点。"), session: session, screen: nil)
        input.handle(snapshot("我今天会晚一點。"), session: session, screen: nil)
        input.handle(snapshot("我今天会晚一点。"), session: session, screen: nil)

        XCTAssertEqual(received, ["我今天会晚一点。", "我今天会晚一點。", "我今天会晚一点。"])
    }

    func testElectronPlaceholderIsNotUserInput() {
        XCTAssertTrue(
            InputPlaceholderPolicy.isPlaceholder(
                text: "输入消息，按 Enter 发送，输入 / 选择工具或操作，输入 @ 引用话题",
                accessibilityPlaceholder: nil))
        XCTAssertTrue(InputPlaceholderPolicy.isPlaceholder(text: "写消息", accessibilityPlaceholder: "写消息"))
        XCTAssertFalse(InputPlaceholderPolicy.isPlaceholder(text: "这是用户输入", accessibilityPlaceholder: nil))
    }

    func testSettingTheExistingSourceLanguageDoesNotResetInput() {
        let input = InputCoordinator()
        var emptyNotifications = 0
        input.onEmpty = { emptyNotifications += 1 }

        input.setSourceLanguage(.chinese)

        XCTAssertEqual(emptyNotifications, 0)
        input.setSourceLanguage(.english)
        XCTAssertEqual(emptyNotifications, 1)
    }

    func testEmptyInputCancelsThePendingPauseTranslation() async {
        let input = InputCoordinator()
        input.timing = .pause
        input.delayMilliseconds = 20
        let session = InputSessionID(pid: 1)
        var received: String?
        var emptyNotifications = 0
        input.onSentence = { source, _, _, _, _, _, _ in received = source.text }
        input.onEmpty = { emptyNotifications += 1 }

        input.handle(snapshot("你"), session: session, screen: nil)
        input.handle(snapshot(""), session: session, screen: nil)
        try? await Task.sleep(for: .milliseconds(80))

        XCTAssertEqual(emptyNotifications, 1)
        XCTAssertNil(received)
    }
}
