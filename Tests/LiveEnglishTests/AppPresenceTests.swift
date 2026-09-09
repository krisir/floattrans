import AppKit
import XCTest

@testable import LiveEnglish

@MainActor
final class AppPresenceTests: XCTestCase {
    func testClosedOrHiddenChromeDoesNotCount() {
        XCTAssertFalse(AppPresence.countsAsChrome(isVisible: false, isMiniaturized: false))
        XCTAssertTrue(AppPresence.countsAsChrome(isVisible: true, isMiniaturized: false))
        XCTAssertTrue(AppPresence.countsAsChrome(isVisible: false, isMiniaturized: true))
        XCTAssertTrue(AppPresence.countsAsChrome(isVisible: true, isMiniaturized: true))
        XCTAssertFalse(AppPresence.countsAsChrome(nil))
    }

    func testPolicyIsAccessoryWithoutChrome() {
        XCTAssertEqual(AppPresence.activationPolicy(settingsPresent: false, welcomePresent: false), .accessory)
        XCTAssertEqual(AppPresence.activationPolicy(settings: nil, welcome: nil), .accessory)
    }

    func testPolicyIsRegularWhenEitherChromeWindowIsPresent() {
        XCTAssertEqual(AppPresence.activationPolicy(settingsPresent: true, welcomePresent: false), .regular)
        XCTAssertEqual(AppPresence.activationPolicy(settingsPresent: false, welcomePresent: true), .regular)
        XCTAssertEqual(AppPresence.activationPolicy(settingsPresent: true, welcomePresent: true), .regular)
    }

    func testRetainedClosedWindowIsNotChrome() {
        let window = makeRetainedWindow()
        window.orderFrontRegardless()
        XCTAssertTrue(AppPresence.countsAsChrome(window))
        XCTAssertEqual(AppPresence.activationPolicy(settings: window, welcome: nil), .regular)
        window.close()
        XCTAssertFalse(AppPresence.countsAsChrome(window))
        XCTAssertEqual(AppPresence.activationPolicy(settings: window, welcome: nil), .accessory)
    }

    func testClosingWindowIsExcludedEvenIfStillVisible() {
        let settings = makeRetainedWindow()
        let welcome = makeRetainedWindow()
        settings.orderFrontRegardless()
        welcome.orderFrontRegardless()
        XCTAssertEqual(AppPresence.activationPolicy(settings: settings, welcome: welcome, closing: settings), .regular)
        XCTAssertEqual(AppPresence.activationPolicy(settings: settings, welcome: nil, closing: settings), .accessory)
        settings.close()
        welcome.close()
    }

    func testUnrelatedVisibleWindowDoesNotGrantPresence() {
        let overlay = makeRetainedWindow()
        overlay.orderFrontRegardless()
        XCTAssertEqual(AppPresence.activationPolicy(settings: nil, welcome: nil), .accessory)
        overlay.close()
    }

    func testReopenPrefersSettingsOverWelcome() {
        let settings = makeRetainedWindow()
        let welcome = makeRetainedWindow()
        settings.orderFrontRegardless()
        welcome.orderFrontRegardless()
        XCTAssertTrue(AppPresence.windowToReopen(settings: settings, welcome: welcome) === settings)
        settings.close()
        XCTAssertTrue(AppPresence.windowToReopen(settings: settings, welcome: welcome) === welcome)
        welcome.close()
        XCTAssertNil(AppPresence.windowToReopen(settings: settings, welcome: welcome))
    }

    func testRevealThenCloseRestoresAccessoryPolicy() {
        let previous = NSApp.activationPolicy()
        defer { NSApp.setActivationPolicy(previous) }
        let window = makeRetainedWindow()
        AppPresence.reveal(window)
        XCTAssertEqual(NSApp.activationPolicy(), .regular)
        window.close()
        AppPresence.apply(AppPresence.activationPolicy(settings: window, welcome: nil, closing: window))
        XCTAssertEqual(NSApp.activationPolicy(), .accessory)
    }

    func testLaunchPlistKeepsLSUIElement() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/Info.plist")
        let plist = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as? [String: Any]
        )
        XCTAssertEqual(plist["LSUIElement"] as? Bool, true)
    }

    private func makeRetainedWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 80, height: 60),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        return window
    }
}
