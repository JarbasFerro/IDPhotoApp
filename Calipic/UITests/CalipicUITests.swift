import XCTest

final class CalipicUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        executionTimeAllowance = 60
    }

    /// Scrolls the first scroll view (or list) until `element` is hittable, dragging in the right-hand gutter so
    /// the portrait's own drag gesture is not triggered.
    @MainActor
    /// `bottomClearance` also scrolls a hittable element up out of the bottom band, where a drag would be read as
    /// the system's go-home swipe.
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, attempts: Int = 8, bottomClearance: CGFloat = 0) {
        for _ in 0..<attempts where !(element.exists && element.isHittable)
            || (bottomClearance > 0 && element.frame.maxY > app.frame.height - bottomClearance) {
            let scroll = app.scrollViews.firstMatch.exists ? app.scrollViews.firstMatch
                : app.collectionViews.firstMatch.exists ? app.collectionViews.firstMatch : nil
            guard let scroll else { return }
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.85))
                .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.3)))
        }
    }

    /// Waits until a button that is disabled while files are being made accepts taps again.
    @MainActor
    private func waitUntilEnabled(_ element: XCUIElement, timeout: TimeInterval = 20) {
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND isEnabled == true"), object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [enabled], timeout: timeout), .completed, "\(element) never became enabled")
    }

    @MainActor
    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// The same screen in light and in dark; the appearance change is asynchronous.
    @MainActor
    private func attachBothAppearances(_ app: XCUIApplication, _ name: String) {
        attach(app, name)
        XCUIDevice.shared.appearance = .dark
        Thread.sleep(forTimeInterval: 1.5)
        attach(app, name + ", dark")
        XCUIDevice.shared.appearance = .light
        Thread.sleep(forTimeInterval: 1.0)
    }

    /// Identifier lookup independent of the element type SwiftUI chose for the container.
    @MainActor
    private func any(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    @MainActor
    func testHomeAndRequirements() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--uitesting-fresh")
        app.launch()
        XCTAssertTrue(app.buttons["choosePhoto"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["takePhoto"].exists)
        XCTAssertFalse(app.buttons["yourSheet"].exists)
        let homeScreenshot = XCTAttachment(screenshot: app.screenshot())
        homeScreenshot.name = "Home"
        homeScreenshot.lifetime = .keepAlways
        add(homeScreenshot)
        XCTAssertTrue(any(app, "homeHero").exists)
        // Easter egg: a tap on the sample brings another person.
        any(app, "homeHero").tap()
        Thread.sleep(forTimeInterval: 0.8)
        attach(app, "Home, another sample")
        XCUIDevice.shared.appearance = .dark
        Thread.sleep(forTimeInterval: 1.5) // The appearance change is asynchronous.
        let darkScreenshot = XCTAttachment(screenshot: app.screenshot())
        darkScreenshot.name = "Home, dark"
        darkScreenshot.lifetime = .keepAlways
        add(darkScreenshot)
        XCUIDevice.shared.appearance = .light
        let version = app.staticTexts["appVersion"]
        XCTAssertTrue(version.exists)
        // The accessibility label reads "Version 0.9.0 (52)".
        XCTAssertTrue(version.label.range(of: #"\d+\.\d+\.\d+ \(\d+\)$"#, options: .regularExpression) != nil, version.label)
        app.buttons["requirementsLink"].tap()
        XCTAssertTrue(app.staticTexts["Official sources"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["choosePhoto"].exists)
        app.buttons["choosePhoto"].tap()
        XCTAssertTrue(app.staticTexts["Spain · DNI"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["preparationContinue"].exists)
        let preparationScreenshot = XCTAttachment(screenshot: app.screenshot())
        preparationScreenshot.name = "Preparation"
        preparationScreenshot.lifetime = .keepAlways
        add(preparationScreenshot)
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["choosePhoto"].waitForExistence(timeout: 5))
        try app.performAccessibilityAudit(for: [.elementDetection, .hitRegion, .sufficientElementDescription])
    }

    /// Choose an official profile from the catalog, then a custom size from a shortcut (ADR-047, ADR-018).
    @MainActor
    func testDocumentPickerAndCustomSize() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--uitesting-fresh")
        app.launch()
        XCTAssertTrue(app.buttons["documentCard"].waitForExistence(timeout: 10))
        app.buttons["documentCard"].tap()
        // Lists only create rows on screen; search the way a person would.
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("United States")
        let usPassport = app.buttons["profile-us.passport.standard"]
        XCTAssertTrue(usPassport.waitForExistence(timeout: 5))
        let pickerScreenshot = XCTAttachment(screenshot: app.screenshot())
        pickerScreenshot.name = "Document picker"
        pickerScreenshot.lifetime = .keepAlways
        add(pickerScreenshot)
        usPassport.tap()
        let card = app.buttons["documentCard"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertTrue(card.label.contains("United States · Passport"), card.label)

        app.buttons["documentCard"].tap()
        XCTAssertTrue(app.buttons["customSizeRow"].waitForExistence(timeout: 5))
        app.buttons["customSizeRow"].tap()
        XCTAssertTrue(app.buttons["shortcut-35x45"].waitForExistence(timeout: 5))
        app.buttons["shortcut-35x45"].tap()
        let customScreenshot = XCTAttachment(screenshot: app.screenshot())
        customScreenshot.name = "Custom size"
        customScreenshot.lifetime = .keepAlways
        add(customScreenshot)
        app.buttons["useCustomSize"].tap()
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertTrue(card.label.contains("Custom size"), card.label)
        try app.performAccessibilityAudit(for: [.elementDetection, .hitRegion, .sufficientElementDescription])
    }

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

    /// Opens Settings from Home, taps "App Icon", and returns the icon buttons of the sheet.
    @MainActor
    private func openAppIconPicker(_ app: XCUIApplication) throws -> XCUIElementQuery {
        XCTAssertTrue(app.buttons["choosePhoto"].waitForExistence(timeout: 10))
        app.buttons["settingsButton"].tap()
        let row = app.buttons["appIconRow"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.navigationBars["App Icon"].waitForExistence(timeout: 5))
        return app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'appIcon-'"))
    }

    /// Custom size: framing, White or Light grey background, and black and white (ADR-018), in light and dark.
    @MainActor
    func testCustomSizeAdjustControls() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-custom-size", "--uitesting-fixture"]
        app.launchArguments.append("--uitesting-fresh")
        app.launch()
        XCTAssertTrue(any(app, "photoCheck").waitForExistence(timeout: 15))
        reveal(app.buttons["adjust"], in: app)
        app.buttons["adjust"].tap()
        XCTAssertTrue(app.otherElements["cropPreview"].waitForExistence(timeout: 10))
        app.buttons["tool-crop"].tap()
        XCTAssertTrue(app.segmentedControls["framingPicker"].waitForExistence(timeout: 5))
        app.buttons["tool-background"].tap()
        let background = app.segmentedControls["backgroundPicker"]
        XCTAssertTrue(background.waitForExistence(timeout: 5))
        XCTAssertTrue(background.buttons["White"].exists)
        XCTAssertTrue(background.buttons["Light grey"].exists)
        app.buttons["tool-light"].tap()
        let mono = app.switches["monochromeToggle"]
        XCTAssertTrue(mono.waitForExistence(timeout: 5))
        for (appearance, name) in [(XCUIDevice.Appearance.light, "Adjust, custom size, light"),
                                   (XCUIDevice.Appearance.dark, "Adjust, custom size, dark")] {
            XCUIDevice.shared.appearance = appearance
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = name
            shot.lifetime = .keepAlways
            add(shot)
        }
        XCUIDevice.shared.appearance = .light
        try app.performAccessibilityAudit(for: [.elementDetection, .hitRegion, .sufficientElementDescription])
    }

    @MainActor
    func testCheckAdjustSheetShareFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-fixture"]
        app.launchArguments.append("--uitesting-fresh")
        app.launch()
        // Import lands on Photo Check.
        XCTAssertTrue(any(app, "photoCheck").waitForExistence(timeout: 15))
        XCTAssertTrue(any(app, "checkHeadline").waitForExistence(timeout: 15))
        // The document's own by-eye checks fold into one row and open on tap.
        let byEye = any(app, "byEyeRow")
        XCTAssertTrue(byEye.exists)
        let checkScreenshot = XCTAttachment(screenshot: app.screenshot())
        checkScreenshot.name = "Photo Check"
        checkScreenshot.lifetime = .keepAlways
        add(checkScreenshot)
        XCUIDevice.shared.appearance = .dark
        Thread.sleep(forTimeInterval: 1.5)
        let checkDark = XCTAttachment(screenshot: app.screenshot())
        checkDark.name = "Photo Check, dark"
        checkDark.lifetime = .keepAlways
        add(checkDark)
        XCUIDevice.shared.appearance = .light
        // Scroll the row clear of the bottom action bar before tapping it.
        XCTAssertTrue(any(app, "stepMarker").exists)
        let continueButton = app.buttons["outputPrint"]
        for _ in 0..<6 where byEye.frame.maxY > continueButton.frame.minY - 8 {
            app.scrollViews.firstMatch.swipeUp()
        }
        byEye.tap()
        let eyesOpen = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Eyes open")).firstMatch
        XCTAssertTrue(eyesOpen.waitForExistence(timeout: 5), app.debugDescription)
        attach(app, "Photo Check, checks")
        app.buttons["checkDetailsDone"].tap()
        XCTAssertTrue(app.buttons["checkDetailsDone"].waitForNonExistence(timeout: 5))
        // The measured row opens its own list, not the by-eye one.
        any(app, "measuredRow").tap()
        XCTAssertTrue(app.buttons["checkDetailsDone"].waitForExistence(timeout: 5))
        XCTAssertFalse(eyesOpen.exists)
        attach(app, "Photo Check, measured list")
        app.buttons["checkDetailsDone"].tap()
        XCTAssertTrue(app.buttons["checkDetailsDone"].waitForNonExistence(timeout: 5))
        // Adjust: direct manipulation plus the details sliders.
        reveal(app.buttons["adjust"], in: app)
        app.buttons["adjust"].tap()
        XCTAssertTrue(app.otherElements["cropPreview"].waitForExistence(timeout: 10))
        app.buttons["tool-background"].tap()
        XCTAssertTrue(app.segmentedControls["backgroundPicker"].waitForExistence(timeout: 5))
        let adjustTopScreenshot = XCTAttachment(screenshot: app.screenshot())
        adjustTopScreenshot.name = "Adjust, top"
        adjustTopScreenshot.lifetime = .keepAlways
        add(adjustTopScreenshot)
        app.buttons["tool-crop"].tap()
        XCTAssertTrue(app.buttons["Zoom In"].waitForExistence(timeout: 5))
        app.buttons["Zoom In"].tap()
        let zoom = app.sliders["Zoom"]
        XCTAssertTrue(zoom.waitForExistence(timeout: 5))
        // A slider in the bottom band turns the drag into the system's go-home swipe and backgrounds the app.
        XCTAssertLessThan(zoom.frame.maxY, app.frame.height - 150)
        zoom.adjust(toNormalizedSliderPosition: 0.3)
        let adjustScreenshot = XCTAttachment(screenshot: app.screenshot())
        adjustScreenshot.name = "Adjust"
        adjustScreenshot.lifetime = .keepAlways
        add(adjustScreenshot)
        // If this tap is lost, the Adjust sheet stays open and every later step fails with a misleading
        // message, so make sure the sheet is really gone before moving on.
        let adjustDone = app.buttons["adjustDone"]
        adjustDone.tap()
        if !adjustDone.waitForNonExistence(timeout: 3) { adjustDone.tap() }
        XCTAssertTrue(adjustDone.waitForNonExistence(timeout: 5))
        // Sheet.
        reveal(app.buttons["outputPrint"], in: app)
        XCTAssertTrue(app.buttons["outputPrint"].waitForExistence(timeout: 5))
        app.buttons["outputPrint"].tap()
        XCTAssertTrue(app.staticTexts["layoutSummary"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["continueToShare"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.steppers["copiesStepper"].exists)
        attachBothAppearances(app, "Your sheet")
        app.buttons["continueToShare"].tap()
        // Print: nothing can leave the app until the photo is unlocked with a credit (ADR-048, ADR-049).
        XCTAssertTrue(any(app, "unlockCard").waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["creditBalanceLine"].label.contains("1"))
        XCTAssertFalse(app.buttons["printAtHome"].exists)
        XCTAssertFalse(app.buttons["moreFormats"].exists)
        XCTAssertFalse(app.buttons["shareDone"].exists)
        attachBothAppearances(app, "Print, locked")
        app.buttons["unlockAndPrint"].tap()
        // Unlocked: print at home or at a shop; other files under More formats.
        // Unlocked: where to print is an explicit choice before the main button works.
        XCTAssertTrue(app.buttons["chooseRouteFirst"].waitForExistence(timeout: 10))
        attachBothAppearances(app, "Print, choose where")
        app.buttons["routeHome"].tap()
        XCTAssertTrue(app.buttons["printAtHome"].waitForExistence(timeout: 10))
        waitUntilEnabled(app.buttons["moreFormats"])
        attachBothAppearances(app, "Print")
        app.buttons["moreFormats"].tap()
        XCTAssertTrue(app.buttons["shareJPEG"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["sharePDF"].exists)
        attach(app, "More formats")
        app.buttons["formatsDone"].tap()
        XCTAssertTrue(app.buttons["formatsDone"].waitForNonExistence(timeout: 5))
        // At a shop: the steps change and the main button shares the print image directly, with no extra sheet.
        app.buttons["routeShop"].tap()
        XCTAssertTrue(any(app, "sharePages").waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["printAtHome"].exists)
        attachBothAppearances(app, "Print at a shop")
        app.buttons["shareDone"].tap()
        // Back home with the session kept.
        XCTAssertTrue(app.buttons["yourSheet"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["takePhoto"].exists)
        try app.performAccessibilityAudit(for: [.elementDetection, .hitRegion, .sufficientElementDescription])
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

    /// An unlocked photo is final: editing it asks first, and going ahead locks it again (ADR-048).
    @MainActor
    func testEditingAnUnlockedPhotoAsksFirst() throws {
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
        waitUntilEnabled(app.buttons["moreFormats"])
        // Back to the sheet, then to the photo.
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["person-1"].waitForExistence(timeout: 5))
        app.buttons["person-1"].tap()
        XCTAssertTrue(any(app, "unlockedNote").waitForExistence(timeout: 10))
        attach(app, "Photo Check, unlocked")
        reveal(app.buttons["adjust"], in: app)
        app.buttons["adjust"].tap()
        let edit = app.buttons["Edit Photo"]
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        attach(app, "This photo is final")
        edit.tap()
        XCTAssertTrue(any(app, "unlockedNote").waitForNonExistence(timeout: 5))
    }

    /// Reaches Print with the photos unlocked and the files ready.
    @MainActor
    private func launchToUnlockedPrint() -> XCUIApplication {
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
        waitUntilEnabled(app.buttons["moreFormats"])
        app.buttons["routeHome"].tap()
        return app
    }

    /// Two pages: Print shows a small stack and says how many pages (0.20.10); the stepper then moves by pages.
    @MainActor
    func testPrintShowsAStackForSeveralPages() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-fixture"]
        app.launchArguments.append("--uitesting-fresh")
        app.launch()
        XCTAssertTrue(any(app, "photoCheck").waitForExistence(timeout: 15))
        reveal(app.buttons["outputPrint"], in: app)
        app.buttons["outputPrint"].tap()
        let summary = app.staticTexts["layoutSummary"]
        XCTAssertTrue(app.buttons["fillPages"].waitForExistence(timeout: 10))
        // A part-filled page outlines its free slots and says how many more fit.
        XCTAssertTrue(summary.waitForExistence(timeout: 10))
        XCTAssertTrue(summary.label.contains("Room for"), summary.label)
        sleep(2)
        attachBothAppearances(app, "Your sheet, free slots")
        app.buttons["fillPages"].tap()
        let twoPages = app.buttons.matching(NSPredicate(format: "label BEGINSWITH '2 pages'")).firstMatch
        XCTAssertTrue(twoPages.waitForExistence(timeout: 5))
        twoPages.tap()
        XCTAssertTrue(summary.label.contains("2 pages"), summary.label)
        // The stepper moves one copy at a time, also beyond a full page.
        app.steppers["copiesStepper"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(summary.label.contains("23 copies") && summary.label.contains("2 pages"), summary.label)
        app.steppers["copiesStepper"].buttons.element(boundBy: 1).tap()
        XCTAssertTrue(summary.label.contains("24 copies"), summary.label)
        app.buttons["continueToShare"].tap()
        XCTAssertTrue(any(app, "printHeader").waitForExistence(timeout: 10))
        XCTAssertTrue(any(app, "printHeader").label.contains("2 pages"), any(app, "printHeader").label)
        attachBothAppearances(app, "Print, two pages")
    }

    /// After printing, the person compares the print with the screen: a wrong size leads to the fix, a right size to Finished.
    @MainActor
    func testPrintCheckLeadsToTheFixOrToFinished() throws {
        let app = launchToUnlockedPrint()
        let check = app.buttons["checkPrintButton"]
        XCTAssertTrue(check.waitForExistence(timeout: 5))
        reveal(check, in: app, bottomClearance: 240)
        attach(app, "Print, unlocked")
        check.tap()
        XCTAssertTrue(any(app, "trueSizeReference").waitForExistence(timeout: 5))
        attachBothAppearances(app, "Check your print")
        app.buttons["checkNoMatch"].tap()
        XCTAssertTrue(app.buttons["checkSmaller"].waitForExistence(timeout: 5))
        app.buttons["checkSmaller"].tap()
        XCTAssertTrue(any(app, "diagnosisTitle").waitForExistence(timeout: 5))
        attach(app, "Print check, smaller")
        app.buttons["diagnosisClose"].tap()
        XCTAssertTrue(app.buttons["diagnosisClose"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(check.waitForExistence(timeout: 5))
        reveal(check, in: app, bottomClearance: 240)
        check.tap()
        XCTAssertTrue(app.buttons["checkMatches"].waitForExistence(timeout: 5))
        app.buttons["checkMatches"].tap()
        XCTAssertTrue(any(app, "finishedScreen").waitForExistence(timeout: 5))
        attachBothAppearances(app, "Finished")
        app.buttons["finishedDone"].tap()
        XCTAssertTrue(app.buttons["yourSheet"].waitForExistence(timeout: 5))
    }

    /// The shop route offers the same check, but cannot print again from the app.
    @MainActor
    func testShopPrintOffersTheCheck() throws {
        let app = launchToUnlockedPrint()
        app.buttons["routeShop"].tap()
        XCTAssertTrue(any(app, "sharePages").waitForExistence(timeout: 10))
        let check = app.buttons["checkPrintButton"]
        reveal(check, in: app, bottomClearance: 240)
        check.tap()
        XCTAssertTrue(any(app, "trueSizeReference").waitForExistence(timeout: 5))
        app.buttons["checkNoMatch"].tap()
        XCTAssertTrue(app.buttons["checkNotSure"].waitForExistence(timeout: 5))
        app.buttons["checkNotSure"].tap()
        XCTAssertTrue(any(app, "diagnosisTitle").waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["printAgain"].exists)
        attach(app, "Shop print check")
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

    @MainActor
    func testCreditsFromHome() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--uitesting-fresh")
        app.launch()
        let credits = app.buttons["creditsButton"]
        XCTAssertTrue(credits.waitForExistence(timeout: 10))
        XCTAssertTrue(credits.label.contains("1"), credits.label)
        credits.tap()
        XCTAssertTrue(app.staticTexts["creditBalance"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["pack-1"].exists)
        XCTAssertTrue(app.buttons["pack-10"].exists)
        app.buttons["pack-10"].tap()
        XCTAssertTrue(app.staticTexts["creditBalance"].label.contains("11"))
        try app.performAccessibilityAudit(for: [.elementDetection, .hitRegion, .sufficientElementDescription])
        app.buttons["creditsDone"].tap()
        XCTAssertTrue(credits.label.contains("11"), credits.label)
    }

    @MainActor
    func testAccessibilityTextSizeCanReachShare() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-fixture", "-UIPreferredContentSizeCategoryName",
                               "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launchArguments.append("--uitesting-fresh")
        app.launch()
        XCTAssertTrue(any(app, "photoCheck").waitForExistence(timeout: 15))
        reveal(app.buttons["outputPrint"], in: app, attempts: 10)
        XCTAssertTrue(app.buttons["outputPrint"].isHittable)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Photo Check at accessibility text size"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertTrue(app.buttons["outputPrint"].waitForExistence(timeout: 5))
        app.buttons["outputPrint"].tap()
        XCTAssertTrue(app.buttons["continueToShare"].waitForExistence(timeout: 10))
        attach(app, "Your sheet at accessibility text size")
        reveal(app.buttons["continueToShare"], in: app, attempts: 10)
        XCTAssertTrue(app.buttons["continueToShare"].isHittable)
        app.buttons["continueToShare"].tap()
        XCTAssertTrue(app.buttons["unlockAndPrint"].waitForExistence(timeout: 20))
        reveal(app.buttons["unlockAndPrint"], in: app, attempts: 20)
        // The swipe may still be coasting; wait for the button to settle where it can be tapped.
        let hittable = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isHittable == true"), object: app.buttons["unlockAndPrint"])
        XCTAssertEqual(XCTWaiter().wait(for: [hittable], timeout: 5), .completed)
        attach(app, "Print at accessibility text size")
        app.buttons["unlockAndPrint"].tap()
        reveal(app.buttons["routeHome"], in: app, attempts: 10)
        app.buttons["routeHome"].tap()
        XCTAssertTrue(app.buttons["printAtHome"].waitForExistence(timeout: 10))
        reveal(app.buttons["printAtHome"], in: app, attempts: 10)
        XCTAssertTrue(app.buttons["printAtHome"].isHittable)
    }
}
