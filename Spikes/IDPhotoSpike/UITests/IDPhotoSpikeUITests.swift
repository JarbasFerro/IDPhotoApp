import XCTest

final class IDPhotoSpikeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        executionTimeAllowance = 60
    }

    /// Scrolls the first scroll view (or list) until `element` is hittable, dragging in the right-hand gutter so
    /// the portrait's own drag gesture is not triggered.
    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, attempts: Int = 8) {
        for _ in 0..<attempts where !(element.exists && element.isHittable) {
            let scroll = app.scrollViews.firstMatch.exists ? app.scrollViews.firstMatch : app.collectionViews.firstMatch
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.85))
                .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.3)))
        }
    }

    /// Identifier lookup independent of the element type SwiftUI chose for the container.
    @MainActor
    private func any(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    @MainActor
    func testHomeAndRequirements() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["choosePhoto"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["takePhoto"].exists)
        XCTAssertFalse(app.buttons["yourSheet"].exists)
        let version = app.staticTexts["appVersion"]
        XCTAssertTrue(version.exists)
        // The accessibility label reads "Version 0.9.0 (52)".
        XCTAssertTrue(version.label.range(of: #"\d+\.\d+\.\d+ \(\d+\)$"#, options: .regularExpression) != nil, version.label)
        app.buttons["documentCard"].tap()
        XCTAssertTrue(app.staticTexts["Before you take the photo"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["choosePhoto"].exists)
        try app.performAccessibilityAudit(for: [.elementDetection, .hitRegion, .sufficientElementDescription])
    }

    @MainActor
    func testCheckAdjustSheetShareFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-fixture"]
        app.launch()
        // Import lands on Photo Check.
        XCTAssertTrue(any(app, "photoCheck").waitForExistence(timeout: 15))
        XCTAssertTrue(any(app, "checkHeadline").waitForExistence(timeout: 15))
        let checkScreenshot = XCTAttachment(screenshot: app.screenshot())
        checkScreenshot.name = "Photo Check"
        checkScreenshot.lifetime = .keepAlways
        add(checkScreenshot)
        // Adjust: direct manipulation plus the details sliders.
        reveal(app.buttons["adjust"], in: app)
        app.buttons["adjust"].tap()
        XCTAssertTrue(app.otherElements["cropPreview"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.segmentedControls["backgroundPicker"].exists)
        reveal(app.buttons["details"], in: app)
        app.buttons["details"].tap()
        let zoom = app.sliders["Zoom"]
        XCTAssertTrue(zoom.waitForExistence(timeout: 5))
        zoom.adjust(toNormalizedSliderPosition: 0.3)
        let adjustScreenshot = XCTAttachment(screenshot: app.screenshot())
        adjustScreenshot.name = "Adjust"
        adjustScreenshot.lifetime = .keepAlways
        add(adjustScreenshot)
        app.buttons["adjustDone"].tap()
        // Sheet.
        reveal(app.buttons["addToSheet"], in: app)
        app.buttons["addToSheet"].tap()
        XCTAssertTrue(app.staticTexts["layoutSummary"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["continueToShare"].waitForExistence(timeout: 5))
        app.buttons["continueToShare"].tap()
        // Share: files prepared on arrival.
        XCTAssertTrue(app.buttons["shareJPEG"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["sharePDF"].exists)
        let shareScreenshot = XCTAttachment(screenshot: app.screenshot())
        shareScreenshot.name = "Share"
        shareScreenshot.lifetime = .keepAlways
        add(shareScreenshot)
        reveal(app.buttons["shareDone"], in: app)
        app.buttons["shareDone"].tap()
        // Back home with the session kept.
        XCTAssertTrue(app.buttons["yourSheet"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["takePhoto"].exists)
        try app.performAccessibilityAudit(for: [.elementDetection, .hitRegion, .sufficientElementDescription])
    }

    @MainActor
    func testCameraUnavailableOffersPhotoImport() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["takePhoto"].waitForExistence(timeout: 10))
        app.buttons["takePhoto"].tap()
        // Simulators have no camera; the screen must explain and offer the import path.
        XCTAssertTrue(app.buttons["cameraUnavailableChoose"].waitForExistence(timeout: 10))
        app.buttons["cameraUnavailableChoose"].tap()
        XCTAssertTrue(app.buttons["choosePhoto"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSheetAddsASizeAndUpdatesTheSummary() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-fixture"]
        app.launch()
        XCTAssertTrue(any(app, "photoCheck").waitForExistence(timeout: 15))
        reveal(app.buttons["addToSheet"], in: app)
        app.buttons["addToSheet"].tap()
        XCTAssertTrue(app.scrollViews["sheetPreview"].waitForExistence(timeout: 10))
        let summary = app.staticTexts["layoutSummary"]
        XCTAssertTrue(summary.waitForExistence(timeout: 5))
        let before = summary.label
        let addSize = app.buttons["addSize-1"]
        reveal(addSize, in: app)
        addSize.tap()
        // The size list is a confirmation dialog; its buttons surface by label.
        let option = app.buttons.matching(NSPredicate(format: "label CONTAINS '45'")).firstMatch
        XCTAssertTrue(option.waitForExistence(timeout: 5))
        option.tap()
        XCTAssertTrue(app.staticTexts["layoutSummary"].waitForExistence(timeout: 5))
        XCTAssertNotEqual(app.staticTexts["layoutSummary"].label, before)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Your sheet"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        try app.performAccessibilityAudit(for: [.elementDetection, .hitRegion, .sufficientElementDescription])
    }

    @MainActor
    func testTwoPeopleShareOneSheetAndExportTwoJPEGs() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-fixture-2"]
        app.launch()
        XCTAssertTrue(any(app, "photoCheck").waitForExistence(timeout: 15))
        XCTAssertTrue(app.navigationBars["Photo 2 of 2"].waitForExistence(timeout: 15))
        reveal(app.buttons["addToSheet"], in: app)
        app.buttons["addToSheet"].tap()
        XCTAssertTrue(app.buttons["person-1"].waitForExistence(timeout: 10))
        reveal(app.buttons["person-2"], in: app)
        XCTAssertTrue(app.buttons["person-2"].exists)
        let composer = XCTAttachment(screenshot: app.screenshot())
        composer.name = "Your sheet, two people"
        composer.lifetime = .keepAlways
        add(composer)
        app.buttons["continueToShare"].tap()
        XCTAssertTrue(app.buttons["shareJPEG"].waitForExistence(timeout: 20))
        reveal(app.buttons["shareAllJPEGs"], in: app)
        XCTAssertTrue(app.buttons["shareJPEG-2"].exists)
        XCTAssertTrue(app.buttons["shareAllJPEGs"].exists)
        reveal(app.buttons["shareDone"], in: app)
        app.buttons["shareDone"].tap()
        // Home shows both faces in the session card.
        XCTAssertTrue(app.buttons["yourSheet"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.images["face-2"].exists || app.buttons["yourSheet"].label.contains("2"))
    }

    @MainActor
    func testAccessibilityTextSizeCanReachShare() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-fixture", "-UIPreferredContentSizeCategoryName",
                               "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(any(app, "photoCheck").waitForExistence(timeout: 15))
        reveal(app.buttons["addToSheet"], in: app, attempts: 10)
        XCTAssertTrue(app.buttons["addToSheet"].isHittable)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Photo Check at accessibility text size"
        attachment.lifetime = .keepAlways
        add(attachment)
        app.buttons["addToSheet"].tap()
        XCTAssertTrue(app.buttons["continueToShare"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["continueToShare"].isHittable)
        app.buttons["continueToShare"].tap()
        XCTAssertTrue(app.buttons["shareJPEG"].waitForExistence(timeout: 20))
        reveal(app.buttons["shareJPEG"], in: app, attempts: 10)
        XCTAssertTrue(app.buttons["shareJPEG"].isHittable)
        let shareScreenshot = XCTAttachment(screenshot: app.screenshot())
        shareScreenshot.name = "Share at accessibility text size"
        shareScreenshot.lifetime = .keepAlways
        add(shareScreenshot)
    }
}
