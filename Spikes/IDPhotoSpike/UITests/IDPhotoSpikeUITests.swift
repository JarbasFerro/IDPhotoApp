import XCTest

final class IDPhotoSpikeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        executionTimeAllowance = 60
    }

    @MainActor
    func testEmptyStateAndRequirements() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["choosePhoto"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["prepareExport"].exists)
        app.buttons["Photo requirements"].tap()
        XCTAssertTrue(app.staticTexts["Before you choose a photo"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["choosePhoto"].exists)
        try app.performAccessibilityAudit(for: [.elementDetection, .hitRegion, .sufficientElementDescription])
    }

    @MainActor
    func testCropAndExportFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-fixture"]
        app.launch()
        XCTAssertTrue(app.otherElements["cropPreview"].waitForExistence(timeout: 15))
        let cropScreenshot = XCTAttachment(screenshot: app.screenshot())
        cropScreenshot.name = "Crop editor"
        cropScreenshot.lifetime = .keepAlways
        add(cropScreenshot)
        let zoom = app.sliders["Zoom"]
        zoom.adjust(toNormalizedSliderPosition: 0.3)
        app.swipeUp()
        app.buttons["prepareExport"].tap()
        XCTAssertTrue(app.buttons["shareJPEG"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["sharePDF"].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Export sheet"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["prepareExport"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testAccessibilityTextSizeCanReachExport() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-fixture", "-UIPreferredContentSizeCategoryName",
                               "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.otherElements["cropPreview"].waitForExistence(timeout: 15))
        for _ in 0..<8 {
            if app.buttons["prepareExport"].isHittable { break }
            // The portrait intentionally owns drag-to-crop; scroll in the outer gutter.
            let scroll = app.scrollViews.firstMatch
            let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.85))
            let end = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.25))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        XCTAssertTrue(app.buttons["prepareExport"].isHittable)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Accessibility text size"
        attachment.lifetime = .keepAlways
        add(attachment)
        app.buttons["prepareExport"].tap()
        XCTAssertTrue(app.navigationBars["Export"].waitForExistence(timeout: 15))
        // List lazily creates offscreen rows at large text sizes.
        for _ in 0..<6 {
            if app.buttons["shareJPEG"].exists && app.buttons["shareJPEG"].isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(app.buttons["shareJPEG"].isHittable)
        let exportScreenshot = XCTAttachment(screenshot: app.screenshot())
        exportScreenshot.name = "Export at accessibility text size"
        exportScreenshot.lifetime = .keepAlways
        add(exportScreenshot)
    }
}
