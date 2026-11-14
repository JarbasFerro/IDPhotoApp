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
        XCTAssertTrue(any(app, "trueSizeReference").waitForExistence(timeout: 15))
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
        XCTAssertTrue(any(app, "trueSizeReference").waitForExistence(timeout: 15))
        app.buttons["checkNoMatch"].tap()
        XCTAssertTrue(app.buttons["checkNotSure"].waitForExistence(timeout: 5))
        app.buttons["checkNotSure"].tap()
        XCTAssertTrue(any(app, "diagnosisTitle").waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["printAgain"].exists)
        attach(app, "Shop print check")
    }
}
