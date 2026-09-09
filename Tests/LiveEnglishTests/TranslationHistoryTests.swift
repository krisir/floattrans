import Foundation
import XCTest
@testable import LiveEnglish

final class TranslationHistoryTests: XCTestCase {
    func testRetentionPrunesExpiredRowsWhenRecording() async throws {
        let (store, cleanup) = try makeStore()
        defer { cleanup() }
        let calendar = Calendar(identifier: .gregorian)
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 9, day: 9, hour: 12)))
        let old = try XCTUnwrap(calendar.date(byAdding: .hour, value: -25, to: now))

        _ = try await store.recordAndLoad(
            sourceText: "expired", translatedText: "过期", sourceLanguage: .english, targetLanguage: .chinese,
            retention: .forever, now: old)
        let entries = try await store.recordAndLoad(
            sourceText: "fresh", translatedText: "新鲜", sourceLanguage: .english, targetLanguage: .chinese,
            retention: .oneDay, now: now)

        XCTAssertEqual(entries.map(\.sourceText), ["fresh"])
    }

    func testSixMonthRetentionUsesCalendarMonths() async throws {
        let (store, cleanup) = try makeStore()
        defer { cleanup() }
        let calendar = Calendar(identifier: .gregorian)
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 9, day: 9, hour: 12)))
        let justInside = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 12)))
        let expired = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 12)))

        _ = try await store.recordAndLoad(
            sourceText: "inside", translatedText: "保留", sourceLanguage: .english, targetLanguage: .chinese,
            retention: .forever, now: justInside)
        _ = try await store.recordAndLoad(
            sourceText: "expired", translatedText: "删除", sourceLanguage: .english, targetLanguage: .chinese,
            retention: .forever, now: expired)

        let entries = try await store.load(retention: .sixMonths, now: now)
        XCTAssertEqual(entries.map(\.sourceText), ["inside"])
    }

    func testHistoryStoresTheLanguagesUsedForThatTranslation() async throws {
        let (store, cleanup) = try makeStore()
        defer { cleanup() }

        let entries = try await store.recordAndLoad(
            sourceText: "Привет", translatedText: "你好", sourceLanguage: .russian, targetLanguage: .chinese,
            retention: .forever)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].sourceLanguage, .russian)
        XCTAssertEqual(entries[0].targetLanguage, .chinese)
        XCTAssertEqual(entries[0].sourceText, "Привет")
        XCTAssertEqual(entries[0].translatedText, "你好")
    }

    func testWhitespaceOnlyHistoryIsNotRecorded() async throws {
        let (store, cleanup) = try makeStore()
        defer { cleanup() }

        let entries = try await store.recordAndLoad(
            sourceText: " \n ", translatedText: "译文", sourceLanguage: .chinese, targetLanguage: .english,
            retention: .forever)

        XCTAssertTrue(entries.isEmpty)
    }

    func testDoNotRecordDoesNotInsertAndKeepsExistingRows() async throws {
        let (store, cleanup) = try makeStore()
        defer { cleanup() }

        _ = try await store.recordAndLoad(
            sourceText: "kept", translatedText: "保留", sourceLanguage: .english, targetLanguage: .chinese,
            retention: .forever)
        let skipped = try await store.recordAndLoad(
            sourceText: "new", translatedText: "新", sourceLanguage: .english, targetLanguage: .chinese,
            retention: .none)
        let loaded = try await store.load(retention: .none)

        XCTAssertEqual(HistoryRetention.allCases.first, HistoryRetention.none)
        XCTAssertNil(HistoryRetention.none.cutoffDate(now: Date()))
        XCTAssertEqual(skipped.map(\.sourceText), ["kept"])
        XCTAssertEqual(loaded.map(\.sourceText), ["kept"])
    }

    func testDeleteAllRemovesEveryRow() async throws {
        let (store, cleanup) = try makeStore()
        defer { cleanup() }

        _ = try await store.recordAndLoad(
            sourceText: "one", translatedText: "一", sourceLanguage: .english, targetLanguage: .chinese,
            retention: .forever)
        _ = try await store.recordAndLoad(
            sourceText: "two", translatedText: "二", sourceLanguage: .english, targetLanguage: .chinese,
            retention: .forever)
        try await store.deleteAll()
        let entries = try await store.load(retention: .forever)

        XCTAssertTrue(entries.isEmpty)
        // Cancel on the confirmation dialog never calls deleteAll; rows stay until this method runs.
    }

    func testMarkdownExportGroupsByDateAndEscapesCells() {
        let entries = [
            TranslationHistoryEntry(
                id: 1,
                createdAt: Date(timeIntervalSince1970: 1_789_000_000),
                sourceLanguage: .english,
                targetLanguage: .chinese,
                sourceText: "first|line\nsecond",
                translatedText: "译文"),
        ]

        let output = TranslationHistoryExporter.markdown(entries, language: .chinese)

        XCTAssertTrue(output.contains("| 序号 | 原文 | 译文 |"))
        XCTAssertTrue(output.contains("first\\|line<br>second"))
        XCTAssertFalse(output.contains("条"))
    }

    func testExcelExportWritesOpenXMLWorkbookAndProtectsFormulaText() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let url = directory.appendingPathComponent("history.xlsx")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let entries = [
            TranslationHistoryEntry(
                id: 1,
                createdAt: Date(),
                sourceLanguage: .english,
                targetLanguage: .chinese,
                sourceText: "=SUM(A1:A2)",
                translatedText: "公式"),
        ]

        try TranslationHistoryExporter.export(entries, format: .excel, language: .chinese, to: url)
        let data = try Data(contentsOf: url)
        let contents = String(decoding: data, as: UTF8.self)

        XCTAssertEqual(Array(data.prefix(2)), [0x50, 0x4B])
        XCTAssertTrue(contents.contains("xl/worksheets/sheet1.xml"))
        XCTAssertTrue(contents.contains("&apos;=SUM(A1:A2)"))
    }

    private func makeStore() throws -> (TranslationHistoryStore, () -> Void) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = try TranslationHistoryStore(databaseURL: directory.appendingPathComponent("history.sqlite"))
        return (store, { try? FileManager.default.removeItem(at: directory) })
    }
}
