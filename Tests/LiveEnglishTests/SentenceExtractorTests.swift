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

    func testConfiguredLanguageDetectorSupportsRequestedDirections() {
        let detector = LanguageTextDetector()
        XCTAssertTrue(detector.contains("Hello world", language: .english))
        XCTAssertTrue(detector.contains("Привет, мир", language: .russian))
        XCTAssertTrue(detector.contains("こんにちは", language: .japanese))
        XCTAssertFalse(detector.contains("123 !?", language: .english))
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

    func testExtractSourceKeepsCaretOccurrenceWhenTextRepeats() {
        let sentence = "你好世界。"
        let text = sentence + sentence
        let extractor = SentenceExtractor()
        let length = (sentence as NSString).length
        let first = extractor.extractSource(
            from: TextSnapshot(
                pid: 1, bundleIdentifier: nil, text: text, selectedRange: NSRange(location: 2, length: 0)))
        let second = extractor.extractSource(
            from: TextSnapshot(
                pid: 1, bundleIdentifier: nil, text: text, selectedRange: NSRange(location: length + 2, length: 0)))
        XCTAssertEqual(first?.capturedText, sentence)
        XCTAssertEqual(second?.capturedText, sentence)
        XCTAssertEqual(first?.range.location, 0)
        XCTAssertEqual(second?.range.location, length)
        XCTAssertNotEqual(first?.range.location, second?.range.location)
    }

    func testReplaceUsesCapturedRangeNotLastOccurrence() {
        let sentence = "你好世界。"
        let field = sentence + sentence
        let source = ExtractedSource(
            text: sentence, capturedText: sentence,
            range: NSRange(location: 0, length: (sentence as NSString).length),
            terminatorRange: nil, wasTruncated: false)
        var written: String?
        XCTAssertTrue(
            FocusedFieldReplacer.replace(currentText: field, capturedSource: source, translation: "Hi.") { text, _ in
                written = text
                return true
            })
        XCTAssertEqual(written, "Hi." + sentence)
    }

    func testReplaceFailsWhenCapturedRangeContentChanged() {
        let source = ExtractedSource(
            text: "你好世界。", capturedText: "你好世界。",
            range: NSRange(location: 0, length: ("你好世界。" as NSString).length),
            terminatorRange: nil, wasTruncated: false)
        XCTAssertFalse(
            FocusedFieldReplacer.replace(
                currentText: "别的内容。后面还是你好世界。", capturedSource: source, translation: "Hi."
            ) { _, _ in
                XCTFail("write should not run when the captured range no longer matches")
                return true
            })
    }

    func testTruncatedSourceIsDisplayOnlyAndDoesNotReplace() {
        let long = String(repeating: "你", count: 301) + "。"
        let extracted = SentenceExtractor().extractSource(
            from: TextSnapshot(
                pid: 1, bundleIdentifier: nil, text: long,
                selectedRange: NSRange(location: (long as NSString).length, length: 0)))
        XCTAssertEqual(extracted?.wasTruncated, true)
        XCTAssertEqual(extracted?.text.count, 300)
        XCTAssertEqual(extracted?.capturedText, long)
        XCTAssertFalse(
            FocusedFieldReplacer.replace(
                currentText: long, capturedSource: extracted!, translation: "Too long."
            ) { _, _ in
                XCTFail("truncated sources must not rewrite the field")
                return true
            })
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

    func testDirectionChangesArePassedToEngine() async {
        let coordinator = TranslationCoordinator(engine: DirectionEchoEngine())
        await coordinator.setDirection(from: .english, to: .russian)
        let translated = await coordinator.translate("Hello")
        XCTAssertEqual(translated, "en-ru:Hello")
    }
}

private struct DirectionEchoEngine: TranslationEngine {
    func translate(_ text: String, from: Language, to: Language) async throws -> String {
        "\(from.rawValue)-\(to.rawValue):\(text)"
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
