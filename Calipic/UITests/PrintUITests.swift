import XCTest

/// Print: where you print, the page stack, Check Your Print.
final class PrintUITests: CalipicUITestCase {
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
        XCTAssertTrue(summary.label.contains("12 copies"), summary.label)
        XCTAssertFalse(summary.label.contains("Room for"), summary.label)
        app.steppers["copiesStepper"].buttons.element(boundBy: 0).tap()
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
        XCTAssertTrue(any(app, "printSummary").label.contains("2 pages"), any(app, "printSummary").label)
        attachBothAppearances(app, "Print, two pages")
    }

    /// After printing, the person compares the print with the screen: a wrong size leads to the fix, a right size to Finished.
    @MainActor
    func testPrintCheckLeadsToTheFixOrToFinished() throws {
        let app = launchToUnlockedPrint()
        let check = app.buttons["checkPrintButton"]
        XCTAssertTrue(check.waitForExistence(timeout: 5))
        reveal(check, in: app)
        attach(app, "Print, unlocked")
        check.tap()
        XCTAssertTrue(any(app, "printCheckInstruction").waitForExistence(timeout: 15))
        XCTAssertTrue(any(app, "trueSizeReference").exists || app.buttons["calibrateWithCard"].exists)
        attachBothAppearances(app, "Check your print")
        app.buttons["checkNoMatch"].tap()
        XCTAssertTrue(app.buttons["checkSmaller"].waitForExistence(timeout: 5))
        app.buttons["checkSmaller"].tap()
        XCTAssertTrue(any(app, "diagnosisTitle").waitForExistence(timeout: 5))
        attach(app, "Print check, smaller")
        app.buttons["diagnosisClose"].tap()
        XCTAssertTrue(app.buttons["diagnosisClose"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(check.waitForExistence(timeout: 5))
        reveal(check, in: app)
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
        if app.buttons["changeRoute"].exists { app.buttons["changeRoute"].tap() }
        app.buttons["routeShop"].tap()
        XCTAssertTrue(any(app, "sharePages").waitForExistence(timeout: 10))
        let check = app.buttons["checkPrintButton"]
        reveal(check, in: app)
        check.tap()
        XCTAssertTrue(any(app, "printCheckInstruction").waitForExistence(timeout: 15))
        XCTAssertTrue(any(app, "trueSizeReference").exists || app.buttons["calibrateWithCard"].exists)
        app.buttons["checkNoMatch"].tap()
        XCTAssertTrue(app.buttons["checkNotSure"].waitForExistence(timeout: 5))
        app.buttons["checkNotSure"].tap()
        XCTAssertTrue(any(app, "diagnosisTitle").waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["printAgain"].exists)
        attach(app, "Shop print check")
    }
}

extension PrintUITests {
    @MainActor
    func testShopOnlySkipsTheRouteChooser() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-fresh", "--uitesting-fixture", "--uitesting-shop-only", "--uitesting-synthetic-only"]
        app.launch()
        XCTAssertTrue(app.buttons["photoMenu"].waitForExistence(timeout: 15))
        app.buttons["photoMenu"].tap()
        app.buttons["outputPrint"].tap()
        XCTAssertTrue(app.buttons["continueToShare"].waitForExistence(timeout: 10))
        app.buttons["continueToShare"].tap()
        app.buttons["unlockAndPrint"].tap()
        XCTAssertTrue(app.buttons["sharePages"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.buttons["routeHome"].exists)
        XCTAssertFalse(app.buttons["chooseRouteFirst"].exists)
        app.buttons["printBack"].tap()
        XCTAssertTrue(app.buttons["continueToShare"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testPrintKeepsThePageThroughTrayStatesAndBack() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-fresh", "--uitesting-fixture", "--uitesting-synthetic-only"]
        app.launch()
        XCTAssertTrue(app.buttons["outputPrint"].waitForExistence(timeout: 15))
        app.buttons["outputPrint"].tap()
        let page = any(app, "sheetPage-0")
        XCTAssertTrue(page.waitForExistence(timeout: 10))
        let originalFrame = page.frame
        XCTAssertGreaterThanOrEqual(originalFrame.height, 300)
        app.buttons["continueToShare"].tap()
        XCTAssertTrue(any(app, "unlockCard").waitForExistence(timeout: 5))
        XCTAssertEqual(page.frame.minY, originalFrame.minY, accuracy: 1)
        XCTAssertEqual(page.frame.height, originalFrame.height, accuracy: 1)
        app.buttons["keepEditing"].tap()
        XCTAssertTrue(app.buttons["continueToShare"].waitForExistence(timeout: 5))
        app.buttons["continueToShare"].tap()
        app.buttons["unlockAndPrint"].tap()
        XCTAssertTrue(app.buttons["chooseRouteFirst"].waitForExistence(timeout: 10))
        XCTAssertEqual(page.frame.minY, originalFrame.minY, accuracy: 1)
        XCTAssertEqual(page.frame.height, originalFrame.height, accuracy: 1)
        app.buttons["routeHome"].tap()
        XCTAssertTrue(app.buttons["printAtHome"].waitForExistence(timeout: 5))
        XCTAssertEqual(page.frame.minY, originalFrame.minY, accuracy: 1)
        XCTAssertEqual(page.frame.height, originalFrame.height, accuracy: 1)
        attach(app, "Print, same page in send state")
        app.buttons["printBack"].tap()
        XCTAssertTrue(app.buttons["routeHome"].waitForExistence(timeout: 5))
        app.buttons["printBack"].tap()
        XCTAssertTrue(app.buttons["continueToShare"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(any(app, "photoCheck").waitForExistence(timeout: 5))
    }
}

extension PrintUITests {
    /// Public, language-independent evidence for every rebuilt tray state. Appearance comes from the simulator.
    @MainActor
    func testPrintAndDigitalVisualStates() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-fresh", "--uitesting-fixture", "--uitesting-public-sample", "--uitesting-measured"]
        app.launch()
        XCTAssertTrue(app.buttons["outputPrint"].waitForExistence(timeout: 15))
        app.buttons["outputPrint"].tap()
        XCTAssertTrue(app.buttons["continueToShare"].waitForExistence(timeout: 10))
        attach(app, "Refinement, print layout")
        XCTAssertTrue(app.buttons["fillPages"].waitForExistence(timeout: 10))
        app.buttons["fillPages"].tap()
        app.buttons["fill-2"].tap()
        attach(app, "Refinement, print two pages")
        app.buttons["fillPages"].tap()
        app.buttons["fill-1"].tap()
        app.buttons["continueToShare"].tap()
        XCTAssertTrue(app.buttons["unlockAndPrint"].waitForExistence(timeout: 5))
        attach(app, "Refinement, print unlock")
        app.buttons["unlockAndPrint"].tap()
        XCTAssertTrue(app.buttons["chooseRouteFirst"].waitForExistence(timeout: 10))
        attach(app, "Refinement, print routes")
        app.buttons["routeHome"].tap()
        XCTAssertTrue(app.buttons["printAtHome"].waitForExistence(timeout: 10))
        attach(app, "Refinement, print home")
        app.buttons["changeRoute"].tap()
        app.buttons["routeShop"].tap()
        XCTAssertTrue(app.buttons["sharePages"].waitForExistence(timeout: 20))
        attach(app, "Refinement, print shop")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["photoMenu"].waitForExistence(timeout: 15))
        app.buttons["photoMenu"].tap()
        app.buttons["outputDigital"].tap()
        XCTAssertTrue(app.buttons["unlockDigital"].waitForExistence(timeout: 10))
        attach(app, "Refinement, digital unlock")
        app.buttons["unlockDigital"].tap()
        XCTAssertTrue(app.buttons["shareDigitalJPEG"].waitForExistence(timeout: 20))
        attach(app, "Refinement, digital ready")
    }
}
