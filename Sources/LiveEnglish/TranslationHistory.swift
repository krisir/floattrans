import Foundation
import SQLite3
import Combine

enum HistoryRetention: String, CaseIterable, Identifiable, Sendable {
    case none
    case oneDay = "1d"
    case sevenDays = "7d"
    case thirtyDays = "30d"
    case sixMonths = "6mo"
    case forever

    var id: String { rawValue }

    func cutoffDate(now: Date, calendar: Calendar = .current) -> Date? {
        switch self {
        case .none, .forever: return nil
        case .oneDay: return calendar.date(byAdding: .day, value: -1, to: now)
        case .sevenDays: return calendar.date(byAdding: .day, value: -7, to: now)
        case .thirtyDays: return calendar.date(byAdding: .day, value: -30, to: now)
        case .sixMonths: return calendar.date(byAdding: .month, value: -6, to: now)
        }
    }
}

struct TranslationHistoryEntry: Identifiable, Equatable, Sendable {
    let id: Int64
    let createdAt: Date
    let sourceLanguage: Language
    let targetLanguage: Language
    let sourceText: String
    let translatedText: String
}

enum HistoryExportFormat: String, CaseIterable, Identifiable {
    case markdown
    case excel

    var id: String { rawValue }
    var fileExtension: String { self == .markdown ? "md" : "xlsx" }
}

enum TranslationHistoryStoreError: LocalizedError {
    case unavailable(String)
    case invalidLanguage

    var errorDescription: String? {
        switch self {
        case .unavailable(let message): return message
        case .invalidLanguage: return "The saved history record has an unsupported language."
        }
    }
}

/// Owns the on-device SQLite database. Translation content never leaves this
/// store unless the user explicitly exports it or chooses an API translator.
actor TranslationHistoryStore {
    private let connection: SQLiteDatabase
    private var database: OpaquePointer { connection.handle }

    init(databaseURL: URL) throws {
        try FileManager.default.createDirectory(
            at: databaseURL.deletingLastPathComponent(), withIntermediateDirectories: true)

        var opened: OpaquePointer?
        let result = sqlite3_open_v2(
            databaseURL.path,
            &opened,
            SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX,
            nil)
        guard result == SQLITE_OK, let opened else {
            let message = opened.map { String(cString: sqlite3_errmsg($0)) } ?? "Unable to open history database."
            if let opened { sqlite3_close(opened) }
            throw TranslationHistoryStoreError.unavailable(message)
        }
        connection = SQLiteDatabase(opened)
        try Self.execute("PRAGMA journal_mode = WAL;", database: opened)
        try Self.execute("""
            CREATE TABLE IF NOT EXISTS translation_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                created_at REAL NOT NULL,
                source_language TEXT NOT NULL,
                target_language TEXT NOT NULL,
                source_text TEXT NOT NULL,
                translated_text TEXT NOT NULL,
                history_key TEXT
            );
            """, database: opened)
        do {
            try Self.execute("ALTER TABLE translation_history ADD COLUMN history_key TEXT;", database: opened)
        } catch {
            // Existing installations already have this column; SQLite does
            // not provide IF NOT EXISTS for ALTER TABLE ADD COLUMN.
            let message = String(describing: error).lowercased()
            guard message.contains("duplicate column") else { throw error }
        }
        try Self.execute(
            "CREATE INDEX IF NOT EXISTS translation_history_created_at ON translation_history(created_at DESC);",
            database: opened)
        try Self.execute(
            "CREATE UNIQUE INDEX IF NOT EXISTS translation_history_history_key ON translation_history(history_key) WHERE history_key IS NOT NULL AND history_key <> '';",
            database: opened)
    }

    static func defaultDatabaseURL(fileManager: FileManager = .default) throws -> URL {
        let support = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true)
        return support
            .appendingPathComponent("FloatTrans", isDirectory: true)
            .appendingPathComponent("translation-history.sqlite", isDirectory: false)
    }

    func recordAndLoad(
        sourceText: String,
        translatedText: String,
        sourceLanguage: Language,
        targetLanguage: Language,
        retention: HistoryRetention,
        historyKey: String? = nil,
        now: Date = .now
    ) throws -> [TranslationHistoryEntry] {
        if retention == .none {
            return try load(retention: retention, now: now)
        }
        let source = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        let translation = translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty, !translation.isEmpty else { return try load(retention: retention, now: now) }

        let hasKey = !(historyKey?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let statement = try prepare(hasKey ? """
            INSERT INTO translation_history
                (created_at, source_language, target_language, source_text, translated_text, history_key)
            VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT(history_key) WHERE history_key IS NOT NULL AND history_key <> '' DO UPDATE SET
                created_at = excluded.created_at,
                source_language = excluded.source_language,
                target_language = excluded.target_language,
                source_text = excluded.source_text,
                translated_text = excluded.translated_text;
            """ : """
            INSERT INTO translation_history
                (created_at, source_language, target_language, source_text, translated_text)
            VALUES (?, ?, ?, ?, ?);
            """)
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_double(statement, 1, now.timeIntervalSince1970)
        bind(sourceLanguage.rawValue, to: statement, at: 2)
        bind(targetLanguage.rawValue, to: statement, at: 3)
        bind(source, to: statement, at: 4)
        bind(translation, to: statement, at: 5)
        if hasKey, let historyKey {
            bind(historyKey, to: statement, at: 6)
        }
        try stepDone(statement)
        return try load(retention: retention, now: now)
    }

    func load(retention: HistoryRetention, now: Date = .now) throws -> [TranslationHistoryEntry] {
        try prune(retention: retention, now: now)
        let statement = try prepare("""
            SELECT id, created_at, source_language, target_language, source_text, translated_text
            FROM translation_history
            ORDER BY created_at DESC, id DESC;
            """)
        defer { sqlite3_finalize(statement) }

        var entries: [TranslationHistoryEntry] = []
        var result = sqlite3_step(statement)
        while result == SQLITE_ROW {
            guard
                let sourceRaw = sqliteString(statement, column: 2),
                let targetRaw = sqliteString(statement, column: 3),
                let sourceLanguage = Language(rawValue: sourceRaw),
                let targetLanguage = Language(rawValue: targetRaw),
                let sourceText = sqliteString(statement, column: 4),
                let translatedText = sqliteString(statement, column: 5)
            else { throw TranslationHistoryStoreError.invalidLanguage }
            entries.append(
                TranslationHistoryEntry(
                    id: sqlite3_column_int64(statement, 0),
                    createdAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 1)),
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage,
                    sourceText: sourceText,
                    translatedText: translatedText))
            result = sqlite3_step(statement)
        }
        if result != SQLITE_DONE {
            throw databaseError()
        }
        return entries
    }

    func prune(retention: HistoryRetention, now: Date = .now) throws {
        guard let cutoff = retention.cutoffDate(now: now) else { return }
        let statement = try prepare("DELETE FROM translation_history WHERE created_at < ?;")
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_double(statement, 1, cutoff.timeIntervalSince1970)
        try stepDone(statement)
    }

    func deleteAll() throws {
        try Self.execute("DELETE FROM translation_history;", database: database)
    }

    private static func execute(_ sql: String, database: OpaquePointer) throws {
        var error: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(database, sql, nil, nil, &error) == SQLITE_OK else {
            let message = error.map { String(cString: $0) } ?? String(cString: sqlite3_errmsg(database))
            sqlite3_free(error)
            throw TranslationHistoryStoreError.unavailable(message)
        }
    }

    private func prepare(_ sql: String) throws -> OpaquePointer {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw databaseError()
        }
        return statement
    }

    private func bind(_ value: String, to statement: OpaquePointer, at index: Int32) {
        sqlite3_bind_text(statement, index, value, -1, sqliteTransient)
    }

    private func stepDone(_ statement: OpaquePointer) throws {
        guard sqlite3_step(statement) == SQLITE_DONE else { throw databaseError() }
    }

    private func sqliteString(_ statement: OpaquePointer, column: Int32) -> String? {
        guard let value = sqlite3_column_text(statement, column) else { return nil }
        return String(cString: value)
    }

    private func databaseError() -> TranslationHistoryStoreError {
        TranslationHistoryStoreError.unavailable(String(cString: sqlite3_errmsg(database)))
    }
}

@MainActor
final class TranslationHistoryController: ObservableObject {
    @Published private(set) var entries: [TranslationHistoryEntry] = []
    @Published private(set) var errorMessage: String?

    private let store: TranslationHistoryStore?

    init(databaseURL: URL? = nil) {
        do {
            store = try TranslationHistoryStore(databaseURL: databaseURL ?? TranslationHistoryStore.defaultDatabaseURL())
        } catch {
            store = nil
            errorMessage = error.localizedDescription
        }
    }

    func reload(retention: HistoryRetention) {
        guard let store else { return }
        Task {
            do {
                entries = try await store.load(retention: retention)
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func record(
        sourceText: String,
        translatedText: String,
        sourceLanguage: Language,
        targetLanguage: Language,
        retention: HistoryRetention,
        historyKey: String? = nil
    ) {
        guard let store else { return }
        Task {
            do {
                entries = try await store.recordAndLoad(
                    sourceText: sourceText,
                    translatedText: translatedText,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage,
                    retention: retention,
                    historyKey: historyKey)
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func deleteAll() {
        guard let store else { return }
        Task {
            do {
                try await store.deleteAll()
                entries = []
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

enum TranslationHistoryExporter {
    static func export(
        _ entries: [TranslationHistoryEntry],
        format: HistoryExportFormat,
        language: UILanguage,
        to url: URL
    ) throws {
        switch format {
        case .markdown:
            try Data(markdown(entries, language: language).utf8).write(to: url, options: .atomic)
        case .excel:
            try xlsx(entries, language: language, to: url)
        }
    }

    static func markdown(_ entries: [TranslationHistoryEntry], language: UILanguage) -> String {
        var output = "# \(L10n.historyExportTitle(language))\n"
        for group in dayGroups(entries) {
            output += "\n## \(dayString(group.day))\n\n"
            output += "| \(L10n.historyIndex(language)) | \(L10n.historyOriginal(language)) | \(L10n.historyTranslation(language)) |\n"
            output += "| --- | --- | --- |\n"
            for (index, entry) in group.entries.enumerated() {
                output += "| \(index + 1) | \(markdownCell(entry.sourceText)) | \(markdownCell(entry.translatedText)) |\n"
            }
        }
        return output
    }

    private static func xlsx(_ entries: [TranslationHistoryEntry], language: UILanguage, to url: URL) throws {
        var rows: [[String]] = [[L10n.historyExportTitle(language), "", ""]]
        for group in dayGroups(entries) {
            rows.append([dayString(group.day), "", ""])
            rows.append([L10n.historyIndex(language), L10n.historyOriginal(language), L10n.historyTranslation(language)])
            for (index, entry) in group.entries.enumerated() {
                rows.append([String(index + 1), excelCell(entry.sourceText), excelCell(entry.translatedText)])
            }
        }
        let archive = [
            StoredZipEntry(name: "[Content_Types].xml", data: Data(contentTypes.utf8)),
            StoredZipEntry(name: "_rels/.rels", data: Data(rootRelationships.utf8)),
            StoredZipEntry(name: "xl/workbook.xml", data: Data(workbook.utf8)),
            StoredZipEntry(name: "xl/_rels/workbook.xml.rels", data: Data(workbookRelationships.utf8)),
            StoredZipEntry(name: "xl/worksheets/sheet1.xml", data: Data(worksheet(rows).utf8)),
        ]
        try StoredZipArchive.write(entries: archive, to: url)
    }

    private static func dayGroups(_ entries: [TranslationHistoryEntry]) -> [(day: Date, entries: [TranslationHistoryEntry])] {
        let calendar = Calendar.current
        var groups: [(day: Date, entries: [TranslationHistoryEntry])] = []
        for entry in entries {
            let day = calendar.startOfDay(for: entry.createdAt)
            if let last = groups.indices.last, calendar.isDate(groups[last].day, inSameDayAs: day) {
                groups[last].entries.append(entry)
            } else {
                groups.append((day, [entry]))
            }
        }
        return groups
    }

    private static func dayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func markdownCell(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "|", with: "\\|")
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\n", with: "<br>")
    }

    private static func excelCell(_ value: String) -> String {
        guard let first = value.trimmingCharacters(in: .whitespacesAndNewlines).first,
            ["=", "+", "-", "@"].contains(first)
        else { return value }
        return "'\(value)"
    }

    private static func worksheet(_ rows: [[String]]) -> String {
        let rowXML = rows.enumerated().map { rowIndex, values in
            let cells = values.enumerated().map { columnIndex, value in
                let reference = "\(columnName(columnIndex + 1))\(rowIndex + 1)"
                return "<c r=\"\(reference)\" t=\"inlineStr\"><is><t xml:space=\"preserve\">\(xml(value))</t></is></c>"
            }.joined()
            return "<row r=\"\(rowIndex + 1)\">\(cells)</row>"
        }.joined()
        return """
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
              <cols><col min="1" max="1" width="10" customWidth="1"/><col min="2" max="3" width="56" customWidth="1"/></cols>
              <sheetData>\(rowXML)</sheetData>
            </worksheet>
            """
    }

    private static func columnName(_ number: Int) -> String {
        String(UnicodeScalar(64 + number)!)
    }

    private static func xml(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private static let contentTypes = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
          <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
          <Default Extension="xml" ContentType="application/xml"/>
          <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
          <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
        </Types>
        """

    private static let rootRelationships = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
        </Relationships>
        """

    private static let workbook = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
          <sheets><sheet name="History" sheetId="1" r:id="rId1"/></sheets>
        </workbook>
        """

    private static let workbookRelationships = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
        </Relationships>
        """
}

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

private final class SQLiteDatabase: @unchecked Sendable {
    let handle: OpaquePointer

    init(_ handle: OpaquePointer) { self.handle = handle }

    deinit { sqlite3_close(handle) }
}

private struct StoredZipEntry {
    let name: String
    let data: Data
}

/// A deliberately small ZIP writer for the uncompressed Open XML spreadsheet
/// package. It avoids adding a network dependency merely to export `.xlsx`.
private enum StoredZipArchive {
    static func write(entries: [StoredZipEntry], to url: URL) throws {
        var archive = Data()
        var centralDirectory = Data()

        for entry in entries {
            let offset = UInt32(archive.count)
            let name = Data(entry.name.utf8)
            let checksum = crc32(entry.data)

            archive.appendLittleEndian(UInt32(0x0403_4B50))
            archive.appendLittleEndian(UInt16(20))
            archive.appendLittleEndian(UInt16(0))
            archive.appendLittleEndian(UInt16(0))
            archive.appendLittleEndian(UInt16(0))
            archive.appendLittleEndian(UInt16(0))
            archive.appendLittleEndian(checksum)
            archive.appendLittleEndian(UInt32(entry.data.count))
            archive.appendLittleEndian(UInt32(entry.data.count))
            archive.appendLittleEndian(UInt16(name.count))
            archive.appendLittleEndian(UInt16(0))
            archive.append(name)
            archive.append(entry.data)

            centralDirectory.appendLittleEndian(UInt32(0x0201_4B50))
            centralDirectory.appendLittleEndian(UInt16(20))
            centralDirectory.appendLittleEndian(UInt16(20))
            centralDirectory.appendLittleEndian(UInt16(0))
            centralDirectory.appendLittleEndian(UInt16(0))
            centralDirectory.appendLittleEndian(UInt16(0))
            centralDirectory.appendLittleEndian(UInt16(0))
            centralDirectory.appendLittleEndian(checksum)
            centralDirectory.appendLittleEndian(UInt32(entry.data.count))
            centralDirectory.appendLittleEndian(UInt32(entry.data.count))
            centralDirectory.appendLittleEndian(UInt16(name.count))
            centralDirectory.appendLittleEndian(UInt16(0))
            centralDirectory.appendLittleEndian(UInt16(0))
            centralDirectory.appendLittleEndian(UInt16(0))
            centralDirectory.appendLittleEndian(UInt16(0))
            centralDirectory.appendLittleEndian(UInt32(0))
            centralDirectory.appendLittleEndian(offset)
            centralDirectory.append(name)
        }

        let centralOffset = UInt32(archive.count)
        archive.append(centralDirectory)
        archive.appendLittleEndian(UInt32(0x0605_4B50))
        archive.appendLittleEndian(UInt16(0))
        archive.appendLittleEndian(UInt16(0))
        archive.appendLittleEndian(UInt16(entries.count))
        archive.appendLittleEndian(UInt16(entries.count))
        archive.appendLittleEndian(UInt32(centralDirectory.count))
        archive.appendLittleEndian(centralOffset)
        archive.appendLittleEndian(UInt16(0))
        try archive.write(to: url, options: .atomic)
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var result: UInt32 = 0xFFFF_FFFF
        for byte in data {
            result ^= UInt32(byte)
            for _ in 0..<8 {
                result = result & 1 == 1 ? (result >> 1) ^ 0xEDB8_8320 : result >> 1
            }
        }
        return ~result
    }
}

private extension Data {
    mutating func appendLittleEndian<T: FixedWidthInteger>(_ value: T) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { append(contentsOf: $0) }
    }
}
