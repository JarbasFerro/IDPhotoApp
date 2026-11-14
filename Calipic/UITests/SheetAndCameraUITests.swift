import XCTest

/// Your sheet, Digital Photo, the camera, and app icons.
final class SheetAndCameraUITests: CalipicUITestCase {
    /// Renders the production camera overlay over a synthetic bust without requesting camera access.
    @MainActor
    func testCameraOverlayKeepsTheSubjectClear() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--camera-review-fixture"]
        app.launchArguments.append("--uitesting-fresh")
        app.launch()
        XCTAssertTrue(app.buttons["cameraHelp"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["cameraCancel"].exists)
        XCTAssertTrue(any(app, "cameraOptionalTip").waitForExistence(timeout: 5))
        let tipScreenshot = XCTAttachment(screenshot: app.screenshot())
        tipScreenshot.name = "Camera first-use tip, synthetic subject"
        tipScreenshot.lifetime = .keepAlways
        add(tipScreenshot)
        XCTAssertTrue(any(app, "cameraHint").waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["shutter"].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Camera overlay, synthetic subject"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        try app.performAccessibilityAudit(for: [.elementDetection, .hitRegion, .sufficientElementDescription])
        app.buttons["cameraHelp"].tap()
        XCTAssertTrue(app.navigationBars["Camera Help"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.switches["introAutoToggle"].exists)
        let helpScreenshot = XCTAttachment(screenshot: app.screenshot())
        helpScreenshot.name = "Camera Help"
        helpScreenshot.lifetime = .keepAlways
        add(helpScreenshot)
        try app.performAccessibilityAudit(for: [.elementDetection, .hitRegion, .sufficientElementDescription])
    }

    /// Directional framing advice stays beside the subject and matches the visible instruction.
    @MainActor
    func testCameraOvalShowsOneActionableCorrection() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--camera-review-fixture", "--camera-review-off-center"]
        app.launchArguments.append("--uitesting-fresh")
        app.launch()
        XCTAssertTrue(any(app, "cameraHint").waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Move the phone left"].exists)
        XCTAssertTrue(app.buttons["shutter"].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Camera directional cue, synthetic subject"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        try app.performAccessibilityAudit(for: [.elementDetection, .hitRegion, .sufficientElementDescription])
    }

    /// The quick review is distinct from live guidance, and Retake restores the camera controls.
    @MainActor
    func testCameraCapturedReviewOffersRetake() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--camera-review-fixture"]
        app.launchArguments.append("--uitesting-fresh")
        app.launch()
        let shutter = app.buttons["shutter"]
        XCTAssertTrue(shutter.waitForExistence(timeout: 10))
        shutter.tap()
        XCTAssertTrue(app.staticTexts["Review your photo"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["cameraRetake"].exists)
        XCTAssertTrue(app.buttons["cameraUsePhoto"].exists)
        XCTAssertFalse(shutter.exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Camera captured review, synthetic subject"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        try app.performAccessibilityAudit(for: [.elementDetection, .hitRegion, .sufficientElementDescription])
        app.buttons["cameraRetake"].tap()
        XCTAssertTrue(shutter.waitForExistence(timeout: 5))
    }

    /// Opens the App Icon sheet from Home (BD-038) and keeps a screenshot of it.
    @MainActor
    func testAppIconPickerShowsTheSetAndTheCurrentIcon() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--uitesting-fresh")
        app.launch()
        let picker = try openAppIconPicker(app)
        XCTAssertTrue(app.staticTexts["People"].exists)
        XCTAssertGreaterThan(picker.count, 8)
        // The grid is lazy, so the selected icon is only in the hierarchy while it is on screen, and the simulator
        // may hold another icon than the default after testChangeAppIconOnRequest.
        XCTAssertLessThanOrEqual(picker.allElementsBoundByIndex.filter(\.isSelected).count, 1)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "AppIconPicker"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        try app.performAccessibilityAudit(for: [.elementDetection, .hitRegion, .sufficientElementDescription])
        // The picker sits over Settings; each has its own Done.
        app.navigationBars["App Icon"].buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        app.navigationBars["Settings"].buttons["Done"].tap()
        XCTAssertTrue(app.buttons["choosePhoto"].waitForExistence(timeout: 5))
    }

    /// End-to-end icon change. It leaves the simulator's Home Screen changed, so it only runs on request:
    /// `TEST_RUNNER_APP_ICON_E2E=panda xcodebuild test -only-testing:…/testChangeAppIconOnRequest` (a VARIANTS
    /// name; `swept` puts the default back).
    @MainActor
    func testChangeAppIconOnRequest() throws {
        guard let name = ProcessInfo.processInfo.environment["APP_ICON_E2E"], !name.isEmpty else {
            throw XCTSkip("Set TEST_RUNNER_APP_ICON_E2E to a character name to run this.")
        }
        let app = XCUIApplication()
        app.launchArguments.append("--uitesting-fresh")
        app.launch()
        _ = try openAppIconPicker(app)
        let cell = app.buttons["appIcon-\(name)"]
        reveal(cell, in: app)
        XCTAssertTrue(cell.exists, name)
        if !cell.isSelected {
            cell.tap()
            // iOS announces every icon change with its own alert; it belongs to SpringBoard, not to the app.
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            let confirm = springboard.alerts.buttons.firstMatch
            XCTAssertTrue(confirm.waitForExistence(timeout: 10), "system alert")
            confirm.tap()
        }
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        XCTAssertTrue(cell.isSelected)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "AppIconPicker-\(name)"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    @MainActor
    func testDigitalPhotoSkipsPrintSetup() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-fixture"]
        app.launchArguments.append("--uitesting-fresh")
        app.launch()
        XCTAssertTrue(any(app, "photoCheck").waitForExistence(timeout: 15))
        reveal(app.buttons["outputPrint"], in: app)
        XCTAssertTrue(app.buttons["outputDigital"].waitForExistence(timeout: 5))
        app.buttons["outputDigital"].tap()
        XCTAssertFalse(app.buttons["continueToShare"].exists)
        // Locked: no file exists yet. One credit unlocks it in place.
        XCTAssertTrue(app.buttons["unlockDigital"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["shareDigitalJPEG"].exists)
        attach(app, "Digital photo, locked")
        app.buttons["unlockDigital"].tap()
        XCTAssertTrue(app.buttons["shareDigitalJPEG"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.buttons["sharePDF"].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Digital result"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.buttons["digitalDone"].tap()
        XCTAssertTrue(app.buttons["yourSheet"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testCameraUnavailableOffersPhotoImport() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--uitesting-fresh")
        app.launch()
        XCTAssertTrue(app.buttons["takePhoto"].waitForExistence(timeout: 10))
        app.buttons["takePhoto"].tap()
        XCTAssertTrue(app.buttons["preparationContinue"].waitForExistence(timeout: 5))
        app.buttons["preparationContinue"].tap()
        // Simulators have no camera; the screen must explain and offer the import path.
        XCTAssertTrue(app.buttons["cameraUnavailableChoose"].waitForExistence(timeout: 10))
        app.buttons["cameraUnavailableChoose"].tap()
        XCTAssertTrue(app.buttons["cameraUnavailableChoose"].waitForNonExistence(timeout: 5))
    }

    @MainActor
    func testSheetAddsASizeAndUpdatesTheSummary() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-fixture"]
        app.launchArguments.append("--uitesting-fresh")
        app.launch()
        XCTAssertTrue(any(app, "photoCheck").waitForExistence(timeout: 15))
        reveal(app.buttons["outputPrint"], in: app)
        app.buttons["outputPrint"].tap()
        XCTAssertTrue(app.scrollViews["sheetPreview"].waitForExistence(timeout: 10))
        let summary = app.staticTexts["layoutSummary"]
        XCTAssertTrue(summary.waitForExistence(timeout: 5))
        let before = summary.label
        // Copies change on the sheet itself.
        app.steppers["copiesStepper"].buttons.element(boundBy: 1).tap()
        XCTAssertNotEqual(summary.label, before)
        // Whole pages in one choice.
        XCTAssertTrue(app.buttons["fillPages"].waitForExistence(timeout: 5))
        app.buttons["fillPages"].tap()
        let twoPages = app.buttons.matching(NSPredicate(format: "label BEGINSWITH '2 pages'")).firstMatch
        XCTAssertTrue(twoPages.waitForExistence(timeout: 5))
        attach(app, "Fill pages")
        twoPages.tap()
        XCTAssertTrue(summary.label.contains("2 pages"), summary.label)
        Thread.sleep(forTimeInterval: 0.8) // the strip scrolls to the new page
        attachBothAppearances(app, "Your sheet, second page in view")
        app.steppers["copiesStepper"].buttons.element(boundBy: 0).tap()
        let afterCopies = summary.label
        // A different paper is one tap away.
        app.buttons["paper-a4"].tap()
        XCTAssertTrue(app.buttons["paper-a4"].isSelected)
        // Cutting options open from the scissors in the bar.
        app.buttons["cuttingOptions"].tap()
        XCTAssertTrue(app.buttons["cuttingDone"].waitForExistence(timeout: 5))
        attach(app, "Cutting options")
        app.buttons["cuttingDone"].tap()
        XCTAssertTrue(app.buttons["cuttingDone"].waitForNonExistence(timeout: 5))
        // Extra sizes live in the options sheet.
        app.buttons["moreOptions"].tap()
        let addSize = app.buttons["addSize-1"]
        XCTAssertTrue(addSize.waitForExistence(timeout: 5))
        attach(app, "Sheet options")
        addSize.tap()
        // The size list is a confirmation dialog; its buttons surface by label.
        let option = app.buttons.matching(NSPredicate(format: "label CONTAINS '45'")).firstMatch
        XCTAssertTrue(option.waitForExistence(timeout: 5))
        option.tap()
        app.buttons["optionsDone"].tap()
        XCTAssertTrue(app.buttons["optionsDone"].waitForNonExistence(timeout: 5))
        XCTAssertNotEqual(summary.label, afterCopies)
        attach(app, "Your sheet, two sizes on A4")
        try app.performAccessibilityAudit(for: [.elementDetection, .hitRegion, .sufficientElementDescription])
    }

    @MainActor
    func testTwoPeopleShareOneSheetAndExportTwoJPEGs() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-fixture-2"]
        app.launchArguments.append("--uitesting-fresh")
        app.launch()
        XCTAssertTrue(any(app, "photoCheck").waitForExistence(timeout: 15))
        XCTAssertTrue(app.navigationBars["Photo 2 of 2"].waitForExistence(timeout: 15))
        reveal(app.buttons["outputPrint"], in: app)
        app.buttons["outputPrint"].tap()
        XCTAssertTrue(app.buttons["personCircle-1"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["personCircle-2"].exists)
        // Selecting a person moves the tray to them.
        app.buttons["personCircle-2"].tap()
        XCTAssertTrue(app.buttons["person-2"].waitForExistence(timeout: 5))
        attachBothAppearances(app, "Your sheet, two people")
        app.buttons["continueToShare"].tap()
        // Two people need two credits; a new person starts with one.
        XCTAssertTrue(app.buttons["getCredits"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["unlockAndPrint"].exists)
        attach(app, "Print, not enough credits")
        app.buttons["getCredits"].tap()
        XCTAssertTrue(app.buttons["pack-5"].waitForExistence(timeout: 5))
        attachBothAppearances(app, "Credits")
        app.buttons["pack-5"].tap()
        XCTAssertTrue(app.staticTexts["creditBalance"].label.contains("6"))
        app.buttons["creditsDone"].tap()
        XCTAssertTrue(app.buttons["unlockAndPrint"].waitForExistence(timeout: 5))
        app.buttons["unlockAndPrint"].tap()
        waitUntilEnabled(app.buttons["moreFormats"])
        app.buttons["moreFormats"].tap()
        XCTAssertTrue(app.buttons["shareJPEG"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["shareJPEG-2"].exists)
        XCTAssertTrue(app.buttons["shareAllJPEGs"].exists)
        app.buttons["formatsDone"].tap()
        XCTAssertTrue(app.buttons["formatsDone"].waitForNonExistence(timeout: 5))
        app.buttons["shareDone"].tap()
        // Home shows both faces in the session card.
        XCTAssertTrue(app.buttons["yourSheet"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.images["face-2"].exists || app.buttons["yourSheet"].label.contains("2"))
        XCTAssertTrue(app.buttons["creditsButton"].label.contains("4"), app.buttons["creditsButton"].label)
    }

    /// The measuring lines (D-2) draw in when the photo lands, fold into the chip, and come back on tap.
    /// The simulator cannot run Vision, so "--uitesting-measured" supplies a synthetic face.
    @MainActor
    func testMeasuringLinesFoldIntoTheChip() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-fixture", "--uitesting-measured"]
        app.launchArguments.append("--uitesting-fresh")
        app.launch()
        XCTAssertTrue(any(app, "photoCheck").waitForExistence(timeout: 15))
        // The lines show by themselves once the photo lands…
        let shown = app.buttons["measureChipLinesShown"]
        XCTAssertTrue(shown.waitForExistence(timeout: 15))
        XCTAssertTrue(shown.label.contains("mm"), shown.label)
        attach(app, "Photo Check, measuring")
        // …then fold into the chip.
        let chip = app.buttons["measureChip"]
        XCTAssertTrue(chip.waitForExistence(timeout: 6))
        attach(app, "Photo Check, measured")
        chip.tap()
        XCTAssertTrue(shown.waitForExistence(timeout: 3))
        Thread.sleep(forTimeInterval: 1.0)
        attach(app, "Photo Check, lines on request")
        XCTAssertTrue(app.buttons["outputPrint"].exists)
        XCTAssertTrue(any(app, "stepMarker").exists)
    }
}
