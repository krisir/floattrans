import XCTest

@testable import LiveEnglish

final class SentenceExtractorTests: XCTestCase {
    func testExtractsSentenceAtCursor() {
        let text = "第一句话。第二句话正在输入。第三句"
        let cursor = (text as NSString).range(of: "第二句话正在输入").location + 3
        let result = SentenceExtractor().extract(
            from: TextSnapshot(
                pid: 1, bundleIdentifier: nil, text: text, selectedRange: NSRange(location: cursor, length: 0)))
        XCTAssertEqual(result, "第二句话正在输入")
    }
    func testChineseDetector() {
        XCTAssertTrue(ChineseTextDetector().containsChinese("Hello，我今天有点忙"))
        XCTAssertFalse(ChineseTextDetector().containsChinese("Hello"))
    }
    func testFallbackUsesLastSegmentWithoutCursor() {
        let snapshot = TextSnapshot(pid: 1, bundleIdentifier: nil, text: "第一句。正在输入的内容", selectedRange: nil)
        XCTAssertEqual(SentenceExtractor().extract(from: snapshot), "正在输入的内容")
    }
    func testPunctuationStillIncludesCompletedSentence() {
        let text = "我今天会晚一点。"
        let snapshot = TextSnapshot(
            pid: 1, bundleIdentifier: nil, text: text,
            selectedRange: NSRange(location: (text as NSString).length, length: 0))
        XCTAssertEqual(SentenceExtractor().extract(from: snapshot), "我今天会晚一点")
    }
}

private actor DelayedEngine: TranslationEngine {
    func translate(_ text: String, from: Language, to: Language) async throws -> String {
        try await Task.sleep(for: .milliseconds(text == "旧" ? 120 : 10))
        return text == "旧" ? "old" : "new"
    }
}

final class TranslationCoordinatorTests: XCTestCase {
    func testNewGenerationWinsWhenOldRequestReturnsLate() async {
        let coordinator = TranslationCoordinator(engine: DelayedEngine())
        async let old = coordinator.translate("旧")
        try? await Task.sleep(for: .milliseconds(20))
        let new = await coordinator.translate("新")
        let oldResult = await old
        XCTAssertEqual(new, "new")
        XCTAssertNil(oldResult)
    }
}
