import XCTest

@testable import LiveEnglish

final class SentenceExtractorTests: XCTestCase {
    func testExtractsSentenceAtCursor() {
        let text = "第一句话。第二句话正在输入。第三句"
        let cursor = (text as NSString).range(of: "第二句话正在输入").location + 3
        let result = SentenceExtractor().extract(
            from: TextSnapshot(
                pid: 1, bundleIdentifier: nil, text: text, selectedRange: NSRange(location: cursor, length: 0)))
        XCTAssertEqual(result, "第二句话正在输入。")
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
        XCTAssertEqual(SentenceExtractor().extract(from: snapshot), "我今天会晚一点。")
    }

    func testExtractIncludesQuestionMark() {
        let text = "你今天来吗？"
        let snapshot = TextSnapshot(
            pid: 1, bundleIdentifier: nil, text: text,
            selectedRange: NSRange(location: (text as NSString).length, length: 0))
        XCTAssertEqual(SentenceExtractor().extract(from: snapshot), "你今天来吗？")
    }

    func testExtractOmitsNewlineTerminator() {
        let text = "我今天会晚一点\n"
        let snapshot = TextSnapshot(
            pid: 1, bundleIdentifier: nil, text: text,
            selectedRange: NSRange(location: (text as NSString).length, length: 0))
        XCTAssertEqual(SentenceExtractor().extract(from: snapshot), "我今天会晚一点")
        XCTAssertTrue(SentenceExtractor().isComplete(snapshot))
    }

    func testExtractMatchesCaretBeforeAndAfterTerminators() {
        let extractor = SentenceExtractor()
        let body = "我今天会晚一点"
        for mark in ["。", ".", "？", "?", "！", "!", "；", ";"] {
            let text = body + mark
            let after = (text as NSString).length
            let before = after - (mark as NSString).length
            let afterSnap = TextSnapshot(
                pid: 1, bundleIdentifier: nil, text: text,
                selectedRange: NSRange(location: after, length: 0))
            let beforeSnap = TextSnapshot(
                pid: 1, bundleIdentifier: nil, text: text,
                selectedRange: NSRange(location: before, length: 0))
            let expected = mark == "\n" ? body : text
            XCTAssertEqual(extractor.extract(from: afterSnap), expected, "after \(mark)")
            XCTAssertEqual(extractor.extract(from: beforeSnap), expected, "before \(mark)")
            XCTAssertEqual(
                extractor.extract(from: afterSnap), extractor.extract(from: beforeSnap), "before/after \(mark)")
        }
    }

    func testExtractFallsBackToPreviousSentenceWhenCaretSliceHasNoChinese() {
        let text = "我今天会晚一点。\u{200B}"
        let snapshot = TextSnapshot(
            pid: 1, bundleIdentifier: nil, text: text,
            selectedRange: NSRange(location: (text as NSString).length, length: 0))
        XCTAssertEqual(SentenceExtractor().extract(from: snapshot), "我今天会晚一点。")
    }

    func testCompleteSentenceRequiresTerminatorAtCaret() {
        let extractor = SentenceExtractor()
        let incomplete = "我今天会晚一点"
        XCTAssertFalse(
            extractor.isComplete(
                TextSnapshot(
                    pid: 1, bundleIdentifier: nil, text: incomplete,
                    selectedRange: NSRange(location: (incomplete as NSString).length, length: 0))))
        for terminator in ["。", "？", "！", ".", "?", "!", "；", ";", "\n"] {
            let complete = "我今天会晚一点" + terminator
            XCTAssertTrue(
                extractor.isComplete(
                    TextSnapshot(
                        pid: 1, bundleIdentifier: nil, text: complete,
                        selectedRange: NSRange(location: (complete as NSString).length, length: 0))),
                "expected complete after \(terminator)")
        }
    }

    func testReplaceRangeCoversSourceAndTerminatorWithPrefix() {
        let field = "昨天很好。我今天会晚一点。"
        let plan = FieldReplacement.evaluate(fieldText: field, source: "我今天会晚一点")
        XCTAssertEqual(plan?.prefix, "昨天很好。")
        XCTAssertEqual(plan?.sourceWithTerminator, "我今天会晚一点。")
        XCTAssertEqual(plan?.suffix, "")
        let applied = plan?.applying(translation: "I will be a bit late today.")
        XCTAssertEqual(applied?.text, "昨天很好。I will be a bit late today.")
        XCTAssertEqual(applied?.caretUTF16Offset, ("昨天很好。I will be a bit late today." as NSString).length)
    }

    func testEvaluateDoesNotAppendSecondTerminatorWhenSourceAlreadyHasPunctuation() {
        let field = "昨天很好。我今天会晚一点。"
        let plan = FieldReplacement.evaluate(fieldText: field, source: "我今天会晚一点。")
        XCTAssertEqual(plan?.prefix, "昨天很好。")
        XCTAssertEqual(plan?.sourceWithTerminator, "我今天会晚一点。")
        XCTAssertEqual(plan?.suffix, "")
    }

    func testEvaluateKeepsIncompleteFragmentWithoutTerminator() {
        let field = "昨天很好。我今天会晚一点"
        let plan = FieldReplacement.evaluate(fieldText: field, source: "我今天会晚一点")
        XCTAssertEqual(plan?.prefix, "昨天很好。")
        XCTAssertEqual(plan?.sourceWithTerminator, "我今天会晚一点")
        XCTAssertEqual(plan?.suffix, "")
    }

    func testReplacingSkipsStaleSourceAndFailedWrite() {
        let field = "昨天很好。我今天会晚一点。"
        XCTAssertNil(
            FieldReplacement.replacing(
                fieldText: field, sourceWithTerminator: "别的句子。", translation: "Other."))
        XCTAssertTrue(
            FocusedFieldReplacer.replace(
                currentText: field, sourceWithTerminator: "我今天会晚一点。", translation: "Late."
            ) { text, caret in
                XCTAssertEqual(text, "昨天很好。Late.")
                XCTAssertEqual(caret, ("昨天很好。Late." as NSString).length)
                return true
            })
        XCTAssertFalse(
            FocusedFieldReplacer.replace(
                currentText: "changed", sourceWithTerminator: "我今天会晚一点。", translation: "Late."
            ) { _, _ in
                XCTFail("write should not run for stale source")
                return true
            })
        XCTAssertFalse(
            FocusedFieldReplacer.replace(
                currentText: field, sourceWithTerminator: "我今天会晚一点。", translation: "Late."
            ) { _, _ in false })
    }
}

final class TranslationClipboardTests: XCTestCase {
    func testCopyWritesReadyTextAndSkipsEmpty() {
        let pasteboard = FakePasteboard()
        pasteboard.contents = "keep-me"
        XCTAssertFalse(TranslationClipboard.copy(nil, using: pasteboard))
        XCTAssertFalse(TranslationClipboard.copy("", using: pasteboard))
        XCTAssertEqual(pasteboard.contents, "keep-me")
        XCTAssertTrue(TranslationClipboard.copy("Hello there.", using: pasteboard))
        XCTAssertEqual(pasteboard.contents, "Hello there.")
    }
}

private final class FakePasteboard: PasteboardWriting {
    var contents: String?
    func writeString(_ text: String) { contents = text }
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

    func testMissingResourcesReturnsNoTranslation() async {
        let coordinator = TranslationCoordinator(engine: MissingResourceEngine())
        let result = await coordinator.translate("你好")
        XCTAssertNil(result)
    }
}

private struct MissingResourceEngine: TranslationEngine {
    func translate(_ text: String, from: Language, to: Language) async throws -> String {
        throw TranslationTestError.missingResources
    }
}

private enum TranslationTestError: Error {
    case missingResources
}
