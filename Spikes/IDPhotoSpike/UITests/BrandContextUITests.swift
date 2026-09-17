import XCTest

/// Product-context evidence for the provisional brand accent candidates (docs/brand/prototypes/04-product-context.md).
/// Each capture test drives the normal flow once and attaches screenshots named `brand-<candidate>-<appearance>-<Screen>`;
/// `scripts/brand/export-brand-screenshots.sh` runs them once per appearance and exports the attachments. They are
/// evidence capture, not regression tests, so they only run when the runner has BRAND_CONTEXT_CAPTURE=1
/// (xcodebuild: TEST_RUNNER_BRAND_CONTEXT_CAPTURE=1); BrandCandidateTests covers the switch itself on every run.
final class BrandContextUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        executionTimeAllowance = 120
    }

    @MainActor func testCaptureBaseline() throws { try capture(candidate: nil) }
    @MainActor func testCaptureA() throws { try capture(candidate: "A") }
    @MainActor func testCaptureB() throws { try capture(candidate: "B") }
    @MainActor func testCaptureC() throws { try capture(candidate: "C") }
    @MainActor func testCaptureD() throws { try capture(candidate: "D") }

    @MainActor
    private func capture(candidate: String?) throws {
        let environment = ProcessInfo.processInfo.environment
        guard environment["BRAND_CONTEXT_CAPTURE"] == "1" else {
            throw XCTSkip("Brand evidence capture only runs with TEST_RUNNER_BRAND_CONTEXT_CAPTURE=1.")
        }
        // The export script sets the simulator's appearance with simctl before each pass (XCUIDevice.appearance had
        // no effect on the iOS 26 simulator) and tells us which one it is, for the attachment names only. The camera
        // screens force a dark scheme, so their shots show the dark accent value under either name.
        let appearance = try XCTUnwrap(environment["BRAND_CONTEXT_APPEARANCE"],
                                       "Set TEST_RUNNER_BRAND_CONTEXT_APPEARANCE to the appearance the simulator is in.")
        let prefix = "brand-\(candidate ?? "baseline")-\(appearance)-"
        let brandArguments = candidate.map { ["-brandCandidate", $0] } ?? []

        // First launch, no photo: Home, then the camera path as far as a simulator allows.
        var app = XCUIApplication()
        app.launchArguments = brandArguments
        app.launch()
        XCTAssertTrue(app.buttons["choosePhoto"].waitForExistence(timeout: 10))
        attach(app, prefix + "Home")
        app.buttons["takePhoto"].tap()
        if app.buttons["introNext"].waitForExistence(timeout: 5) {
            attach(app, prefix + "CameraIntro")
            app.buttons["introNext"].tap()
            XCTAssertTrue(app.buttons["introStart"].waitForExistence(timeout: 5))
            app.buttons["introStart"].tap()
        }
        XCTAssertTrue(app.buttons["cameraUnavailableChoose"].waitForExistence(timeout: 10))
        attach(app, prefix + "CameraUnavailable")
        app.terminate()

        // Second launch with the generated photo: Photo Check, Adjust, Sheet, Share, Home with the session.
        app = XCUIApplication()
        app.launchArguments = ["--uitesting-fixture"] + brandArguments
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["photoCheck"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.descendants(matching: .any)["checkHeadline"].waitForExistence(timeout: 15))
        attach(app, prefix + "PhotoCheck")
        reveal(app.buttons["adjust"], in: app)
        app.buttons["adjust"].tap()
        XCTAssertTrue(app.otherElements["cropPreview"].waitForExistence(timeout: 10))
        attach(app, prefix + "Adjust")
        reveal(app.buttons["details"], in: app)
        app.buttons["details"].tap()
        XCTAssertTrue(app.sliders["Zoom"].waitForExistence(timeout: 5))
        attach(app, prefix + "AdjustDetails")
        app.buttons["adjustDone"].tap()
        reveal(app.buttons["addToSheet"], in: app)
        app.buttons["addToSheet"].tap()
        XCTAssertTrue(app.staticTexts["layoutSummary"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["continueToShare"].waitForExistence(timeout: 5))
        attach(app, prefix + "Sheet")
        app.buttons["continueToShare"].tap()
        XCTAssertTrue(app.buttons["shareJPEG"].waitForExistence(timeout: 20))
        attach(app, prefix + "Share")
        reveal(app.buttons["shareDone"], in: app)
        app.buttons["shareDone"].tap()
        XCTAssertTrue(app.buttons["yourSheet"].waitForExistence(timeout: 5))
        attach(app, prefix + "HomeSession")
    }

    @MainActor
    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Same gutter drag as IDPhotoSpikeUITests.reveal, so the portrait's own drag gesture is not triggered.
    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, attempts: Int = 8) {
        for _ in 0..<attempts where !(element.exists && element.isHittable) {
            let scroll = app.scrollViews.firstMatch.exists ? app.scrollViews.firstMatch
                : app.collectionViews.firstMatch.exists ? app.collectionViews.firstMatch : nil
            guard let scroll else { return }
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.85))
                .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.3)))
        }
    }
}
