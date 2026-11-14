import XCTest

/// The first-photo guide, Home, documents, Settings and credits.
final class GuideAndHomeUITests: CalipicUITestCase {
    /// First-run tutorial (ADR-052): the welcome page, then the coach on Home for the document and the photo.
    @MainActor
    func testTutorialWelcomeAndHome() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-fresh", "--uitesting-tutorial"]
        app.launch()
        XCTAssertTrue(any(app, "tutorialWelcome").waitForExistence(timeout: 10))
        attachBothAppearances(app, "Tutorial, welcome")
        app.buttons["tutorialStart"].tap()
        XCTAssertTrue(coach(app, "sized for this document").waitForExistence(timeout: 10))
        attachBothAppearances(app, "Tutorial, document")
        app.buttons["guideNext"].tap()
        XCTAssertTrue(coach(app, "Then tap Take Photo").waitForExistence(timeout: 5))
        sleep(1)
        attachBothAppearances(app, "Tutorial, photo")
    }

    /// The guided first photo, from Photo Check to the print button, with the real screens.
    @MainActor
    func testTutorialCoachesThePhotoToPrint() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-fresh", "--uitesting-tutorial", "--uitesting-fixture"]
        app.launch()
        XCTAssertTrue(any(app, "tutorialWelcome").waitForExistence(timeout: 10))
        app.buttons["tutorialStart"].tap()
        XCTAssertTrue(any(app, "photoCheck").waitForExistence(timeout: 15))
        XCTAssertTrue(coach(app, "Framed and checked").waitForExistence(timeout: 10))
        sleep(2)
        attachBothAppearances(app, "Tutorial, check result")
        app.buttons["guideNext"].tap()
        XCTAssertTrue(coach(app, "Tap Print").waitForExistence(timeout: 5))
        // Only the way the tutorial continues is offered.
        XCTAssertFalse(app.buttons["outputDigital"].exists)
        sleep(2)
        attachBothAppearances(app, "Tutorial, Photo Check")
        reveal(app.buttons["outputPrint"], in: app)
        app.buttons["outputPrint"].tap()
        XCTAssertTrue(coach(app, "how many copies").waitForExistence(timeout: 10))
        attachBothAppearances(app, "Tutorial, copies")
        app.buttons["guideNext"].tap()
        XCTAssertTrue(coach(app, "paper you'll print on").waitForExistence(timeout: 5))
        attachBothAppearances(app, "Tutorial, paper")
        app.buttons["guideNext"].tap()
        XCTAssertTrue(coach(app, "All set? Tap Continue").waitForExistence(timeout: 5))
        sleep(1)
        attachBothAppearances(app, "Tutorial, continue")
        app.buttons["continueToShare"].tap()
        XCTAssertTrue(coach(app, "one free photo").waitForExistence(timeout: 10))
        attachBothAppearances(app, "Tutorial, unlock")
        app.buttons["unlockAndPrint"].tap()
        XCTAssertTrue(coach(app, "Choose where").waitForExistence(timeout: 10))
        attachBothAppearances(app, "Tutorial, choose where")
        if app.buttons["changeRoute"].exists { app.buttons["changeRoute"].tap() }
        app.buttons["routeHome"].tap()
        XCTAssertTrue(app.buttons["printAtHome"].waitForExistence(timeout: 10))
        XCTAssertTrue(coach(app, "Load photo paper").waitForExistence(timeout: 5))
        attachBothAppearances(app, "Tutorial, print")
        waitUntilEnabled(app.buttons["printAtHome"])
        app.buttons["printAtHome"].tap()
        XCTAssertTrue(any(app, "tutorialAllSet").waitForExistence(timeout: 20))
        sleep(1)
        attachBothAppearances(app, "Tutorial, all set")
        // The guide is over: Check Your Print follows, and the coach is gone.
        app.buttons["tutorialCheckPrint"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(any(app, "coachLine").exists)
        XCTAssertFalse(app.buttons["guideNext"].exists)
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

    /// Settings has a language menu: the iPhone's language or one of the app's three.
    @MainActor
    func testSettingsLanguageMenu() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-fresh"]
        app.launch()
        XCTAssertTrue(app.buttons["choosePhoto"].waitForExistence(timeout: 10))
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(any(app, "languagePicker").waitForExistence(timeout: 5))
        attachBothAppearances(app, "Settings, language")
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
}
