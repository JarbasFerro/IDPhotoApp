import XCTest

/// Shared set-up and helpers for the UI test classes. The tests are split into several classes so a full run can
/// spread them over simulator clones (scripts/test.sh); this class has no tests of its own.
class CalipicUITestCase: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        executionTimeAllowance = 60
    }

    /// Scrolls the first scroll view (or list) until `element` is hittable, dragging in the right-hand gutter so
    /// the portrait's own drag gesture is not triggered.
    @MainActor
    /// `bottomClearance` also scrolls a hittable element up out of the bottom band, where a drag would be read as
    /// the system's go-home swipe.
    func reveal(_ element: XCUIElement, in app: XCUIApplication, attempts: Int = 8, bottomClearance: CGFloat = 0) {
        for _ in 0..<attempts {
            let scroll = app.scrollViews.allElementsBoundByIndex.first {
                $0.identifier != "sheetPreview" && $0.frame.height > 100 && $0.isHittable
            } ?? (app.collectionViews.firstMatch.exists ? app.collectionViews.firstMatch : nil)
            let inside = scroll.map { !element.identifier.isEmpty && $0.descendants(matching: .any)[element.identifier].exists } ?? false
            let clipped = inside && element.frame.maxY > (scroll?.frame.maxY ?? .greatestFiniteMagnitude) + 1
            let needsClearance = bottomClearance > 0 && element.frame.maxY > app.frame.height - bottomClearance
            if element.exists && element.isHittable && !clipped && !needsClearance { return }
            guard let scroll else { return }
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.75))
                .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.25)))
        }
    }

    /// Waits until a button that is disabled while files are being made accepts taps again.
    @MainActor
    func waitUntilEnabled(_ element: XCUIElement, timeout: TimeInterval = 20) {
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND isEnabled == true"), object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [enabled], timeout: timeout), .completed, "\(element) never became enabled")
    }

    @MainActor
    func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// The same screen in light and in dark; the appearance change is asynchronous.
    @MainActor
    func attachBothAppearances(_ app: XCUIApplication, _ name: String) {
        attach(app, name)
        XCUIDevice.shared.appearance = .dark
        Thread.sleep(forTimeInterval: 1.5)
        attach(app, name + ", dark")
        XCUIDevice.shared.appearance = .light
        Thread.sleep(forTimeInterval: 1.0)
    }

    /// Identifier lookup independent of the element type SwiftUI chose for the container.
    @MainActor
    func any(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    /// The guide line, found by what it says.
    @MainActor
    func coach(_ app: XCUIApplication, _ text: String) -> XCUIElement {
        // In another language (screenshot runs with -testLanguage), any guide bubble will do.
        guard Locale.preferredLanguages.first?.hasPrefix("en") ?? true else { return any(app, "coachLine") }
        return app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    /// Opens Settings from Home, taps "App Icon", and returns the icon buttons of the sheet.
    @MainActor
    func openAppIconPicker(_ app: XCUIApplication) throws -> XCUIElementQuery {
        XCTAssertTrue(app.buttons["choosePhoto"].waitForExistence(timeout: 10))
        app.buttons["settingsButton"].tap()
        let row = app.buttons["appIconRow"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.navigationBars["App Icon"].waitForExistence(timeout: 5))
        return app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'appIcon-'"))
    }

    @MainActor
    func waitForPrintFiles(_ app: XCUIApplication) {
        app.buttons["printMenu"].tap()
        waitUntilEnabled(app.buttons["moreFormats"])
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.4)).tap()
    }

    /// Reaches Print with the photos unlocked and the files ready.
    @MainActor
    func launchToUnlockedPrint() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-fixture"]
        app.launchArguments.append("--uitesting-fresh")
        app.launch()
        XCTAssertTrue(any(app, "photoCheck").waitForExistence(timeout: 15))
        reveal(app.buttons["outputPrint"], in: app)
        app.buttons["outputPrint"].tap()
        XCTAssertTrue(app.buttons["continueToShare"].waitForExistence(timeout: 10))
        app.buttons["continueToShare"].tap()
        XCTAssertTrue(app.buttons["unlockAndPrint"].waitForExistence(timeout: 10))
        app.buttons["unlockAndPrint"].tap()
        waitForPrintFiles(app)
        if app.buttons["changeRoute"].exists { app.buttons["changeRoute"].tap() }
        app.buttons["routeHome"].tap()
        return app
    }
}
