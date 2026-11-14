import XCTest

/// Photo Check, Adjust, and the way to Share.
final class PhotoCheckUITests: CalipicUITestCase {
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
        XCTAssertTrue(byEye.waitForExistence(timeout: 10))
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
        XCTAssertTrue(any(app, "stepMarker").exists)
        reveal(byEye, in: app)
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
        XCTAssertFalse(any(app, "creditBalanceLine").exists)
        XCTAssertFalse(app.buttons["printAtHome"].exists)
        XCTAssertFalse(app.buttons["moreFormats"].exists)
        XCTAssertFalse(app.buttons["shareDone"].exists)
        attachBothAppearances(app, "Print, locked")
        app.buttons["unlockAndPrint"].tap()
        // Unlocked: print at home or at a shop; other files under More formats.
        // Unlocked: where to print is an explicit choice before the main button works.
        XCTAssertTrue(app.buttons["chooseRouteFirst"].waitForExistence(timeout: 10))
        attachBothAppearances(app, "Print, choose where")
        if app.buttons["changeRoute"].exists { app.buttons["changeRoute"].tap() }
        app.buttons["routeHome"].tap()
        XCTAssertTrue(app.buttons["printAtHome"].waitForExistence(timeout: 10))
        waitForPrintFiles(app)
        attachBothAppearances(app, "Print")
        app.buttons["printMenu"].tap()
        app.buttons["moreFormats"].tap()
        XCTAssertTrue(app.buttons["shareJPEG"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["sharePDF"].exists)
        attach(app, "More formats")
        app.buttons["formatsDone"].tap()
        XCTAssertTrue(app.buttons["formatsDone"].waitForNonExistence(timeout: 5))
        // At a shop: the steps change and the main button shares the print image directly, with no extra sheet.
        if app.buttons["changeRoute"].exists { app.buttons["changeRoute"].tap() }
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
        waitForPrintFiles(app)
        // Back through the tray states, then leave the layout to return to Photo Check.
        app.buttons["printBack"].tap()
        XCTAssertTrue(app.buttons["continueToShare"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
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
        if app.buttons["changeRoute"].exists { app.buttons["changeRoute"].tap() }
        app.buttons["routeHome"].tap()
        XCTAssertTrue(app.buttons["printAtHome"].waitForExistence(timeout: 10))
        reveal(app.buttons["printAtHome"], in: app, attempts: 10)
        XCTAssertTrue(app.buttons["printAtHome"].isHittable)
    }
}


extension PhotoCheckUITests {
    @MainActor
    func testJourneyTrayScrollKeepsActionsPinned() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-fresh", "--uitesting-journey-tray"]
        app.launch()
        let action = app.buttons["fixtureAction"]
        XCTAssertTrue(action.waitForExistence(timeout: 10))
        let initial = action.frame
        let lastRow = any(app, "fixtureRow-29")
        let scroll = app.scrollViews.firstMatch
        // This fixture has no photo gestures. Drag through its rows, clear of the system scroll indicator.
        for _ in 0..<15 where !lastRow.isHittable {
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75))
                .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)))
        }
        XCTAssertTrue(lastRow.isHittable)
        XCTAssertEqual(action.frame.minY, initial.minY, accuracy: 1)
        XCTAssertTrue(action.isHittable)
        XCTAssertGreaterThan(any(app, "journeyStageFixture").frame.height, app.frame.height * 0.25)
        attach(app, "Shared tray, thirty rows")
    }

    @MainActor
    func testPhotoCheckStageAndOriginal() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-fresh", "--uitesting-fixture", "--uitesting-measured", "--uitesting-synthetic-only"]
        app.launch()
        let chip = app.buttons["measureChip"]
        XCTAssertTrue(chip.waitForExistence(timeout: 15))
        let portrait = any(app, "portrait")
        XCTAssertGreaterThanOrEqual(portrait.frame.height, app.frame.height * 0.45)
        XCTAssertTrue(app.buttons["adjust"].isHittable)
        XCTAssertTrue(app.buttons["outputPrint"].isHittable)
        let original = app.buttons["photoCheck"]
        original.tap()
        XCTAssertEqual(portrait.label, "Original photo")
        let framed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Framed photo"), object: portrait)
        XCTAssertEqual(XCTWaiter.wait(for: [framed], timeout: 3), .completed)
        original.press(forDuration: 0.6)
        XCTAssertEqual(portrait.label, "Framed photo")
        app.buttons["outputPrint"].tap()
        XCTAssertTrue(app.buttons["continueToShare"].waitForExistence(timeout: 10))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(any(app, "measuredRow").waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["measureChipLinesShown"].exists)
        attach(app, "Photo Check, returning without replay")
    }

    @MainActor
    func testPhotoCheckRetakeOffersOutputAnyway() {
        for flag in ["--uitesting-no-face", "--uitesting-closed-eyes"] {
            let app = XCUIApplication()
            app.launchArguments = ["--uitesting-fresh", "--uitesting-fixture", "--uitesting-measured", "--uitesting-synthetic-only", flag]
            app.launch()
            XCTAssertTrue(app.buttons["retakePrimary"].waitForExistence(timeout: 15))
            XCTAssertTrue(app.buttons["outputPrint"].isHittable)
            XCTAssertFalse(app.buttons["adjust"].exists)
            if flag == "--uitesting-closed-eyes" { XCTAssertTrue(any(app, "eyesClosedNote").exists) }
            attach(app, "Photo Check, " + flag)
            app.buttons["photoMenu"].tap()
            XCTAssertTrue(app.buttons["adjust"].waitForExistence(timeout: 5))
            app.terminate()
        }
    }
}
