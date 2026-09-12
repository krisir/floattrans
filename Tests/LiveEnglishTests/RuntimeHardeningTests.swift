import XCTest

@testable import LiveEnglish

final class LLMModelDraftCommitTests: XCTestCase {
    func testDraftEditsDoNotSaveUntilCommit() {
        let model = LLMModelConfiguration(
            name: "DeepSeek", baseURL: "https://api.deepseek.com/v1", model: "deepseek-chat")
        var session = LLMModelDraftCommit(lastCommitted: model, draft: model)
        var saved: [String] = []
        var next = model
        next.apiKey = "sk-1"
        session.noteDraft(next)
        XCTAssertEqual(saved, [])
        XCTAssertTrue(session.commit { saved.append($0.apiKey) })
        XCTAssertEqual(saved, ["sk-1"])
        XCTAssertFalse(session.commit { saved.append($0.apiKey) })
        XCTAssertEqual(saved, ["sk-1"])
    }
}

final class OverlayScreenGeometryTests: XCTestCase {
    func testSecondaryDisplayFrameWinsOverMain() {
        let main = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let secondary = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        let index = OverlayScreenGeometry.screenIndex(
            windowFrame: CGRect(x: 1500, y: 100, width: 400, height: 300),
            mouseLocation: CGPoint(x: 100, y: 100),
            screens: [main, secondary])
        XCTAssertEqual(index, 1)
    }

    func testMouseFallbackWhenWindowFrameMissing() {
        let main = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let secondary = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        let index = OverlayScreenGeometry.screenIndex(
            windowFrame: nil, mouseLocation: CGPoint(x: 1800, y: 200), screens: [main, secondary])
        XCTAssertEqual(index, 1)
    }

    func testAXPointConvertsToCocoaRect() {
        let rect = OverlayScreenGeometry.cocoaRect(
            axPosition: CGPoint(x: 10, y: 20), axSize: CGSize(width: 100, height: 40), desktopMaxY: 900)
        XCTAssertEqual(rect, CGRect(x: 10, y: 840, width: 100, height: 40))
    }
}

final class DiagnosticLogTests: XCTestCase {
    func testFileLoggingIsDebugOnly() {
        #if DEBUG
        XCTAssertTrue(DiagnosticLog.isFileLoggingEnabled)
        #else
        XCTAssertFalse(DiagnosticLog.isFileLoggingEnabled)
        #endif
    }
}

@MainActor
final class GenerationTaggedWaitersTests: XCTestCase {
    func testInvalidateFailsWaitersImmediately() async {
        let waiters = GenerationTaggedWaiters<String>()
        Task { waiters.invalidate() }
        do {
            _ = try await waiters.wait()
            XCTFail("obsolete waiters must fail instead of hanging")
        } catch TranslationSessionError.unavailable {
            // expected
        } catch {
            XCTFail("unexpected \(error)")
        }
    }

    func testResumeAfterInvalidateDoesNotSatisfyOldWaiter() async {
        let waiters = GenerationTaggedWaiters<String>()
        Task {
            waiters.invalidate()
            waiters.resumeMatching("new-pair")
        }
        do {
            _ = try await waiters.wait()
            XCTFail("old request must not receive the new session")
        } catch TranslationSessionError.unavailable {
            // expected
        } catch {
            XCTFail("unexpected \(error)")
        }
    }

    func testMatchingResumeReturnsValue() async throws {
        let waiters = GenerationTaggedWaiters<String>()
        Task { waiters.resumeMatching("ok") }
        let value = try await waiters.wait()
        XCTAssertEqual(value, "ok")
    }
}

@MainActor
final class OverlayHideTimerTests: XCTestCase {
    func testContentUpdateRestartsHideTimer() async {
        let overlay = OverlayCoordinator()
        overlay.hideAfter = 0.12
        overlay.neverHide = false
        overlay.show("first", key: "same", on: NSScreen.main)
        XCTAssertEqual(overlay.visibleCount, 1)
        try? await Task.sleep(for: .milliseconds(70))
        overlay.show("second", key: "same", on: NSScreen.main)
        XCTAssertEqual(overlay.visibleCount, 1)
        try? await Task.sleep(for: .milliseconds(70))
        XCTAssertEqual(overlay.visibleCount, 1)
        try? await Task.sleep(for: .milliseconds(80))
        XCTAssertEqual(overlay.visibleCount, 0)
    }
}

@MainActor
final class TranslationHistoryControllerRaceTests: XCTestCase {
    func testDeleteAllDropsQueuedRecord() async throws {
        let (controller, cleanup) = try makeController()
        defer { cleanup() }
        controller.record(
            sourceText: "queued", translatedText: "排队", sourceLanguage: .chinese, targetLanguage: .english,
            retention: .forever)
        controller.deleteAll()
        await controller.waitForPendingOperations()
        XCTAssertTrue(controller.entries.isEmpty)
        controller.reload(retention: .forever)
        await controller.waitForPendingOperations()
        XCTAssertTrue(controller.entries.isEmpty)
    }

    func testStaleReloadDoesNotRestoreRowsAfterDelete() async throws {
        let (controller, cleanup) = try makeController()
        defer { cleanup() }
        controller.record(
            sourceText: "kept", translatedText: "保留", sourceLanguage: .chinese, targetLanguage: .english,
            retention: .forever)
        await controller.waitForPendingOperations()
        XCTAssertEqual(controller.entries.count, 1)
        controller.reload(retention: .forever)
        controller.deleteAll()
        await controller.waitForPendingOperations()
        XCTAssertTrue(controller.entries.isEmpty)
    }

    private func makeController() throws -> (TranslationHistoryController, () -> Void) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let controller = TranslationHistoryController(
            databaseURL: directory.appendingPathComponent("history.sqlite"))
        return (controller, { try? FileManager.default.removeItem(at: directory) })
    }
}
