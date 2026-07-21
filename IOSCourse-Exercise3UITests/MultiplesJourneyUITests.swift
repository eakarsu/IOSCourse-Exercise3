import XCTest

final class MultiplesJourneyUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-reset-multiples-state"]
    }

    private var statusValue: String? { app.staticTexts["multiples.status"].value as? String }

    func testEmptyAndMalformedInputRecovery() {
        app.launch()
        app.buttons["multiples.start"].tap()
        XCTAssertEqual(statusValue, "Enter a multiplier first.")
        let input = app.textFields["multiples.input"]
        input.tap(); input.typeText("abc")
        app.buttons["multiples.start"].tap()
        XCTAssertEqual(statusValue, "Use a whole number.")
    }

    func testPrimaryFiveStepJourneyWorksOffline() {
        app.launch()
        let input = app.textFields["multiples.input"]
        input.tap(); input.typeText("3")
        app.buttons["multiples.start"].tap()
        for _ in 0..<5 { app.buttons["multiples.add"].tap() }
        XCTAssertEqual(statusValue, "Complete: 15")
    }

    func testLifecycleRestoresProgress() {
        app.launch()
        let input = app.textFields["multiples.input"]
        input.tap(); input.typeText("7")
        app.buttons["multiples.start"].tap(); app.buttons["multiples.add"].tap()
        app.terminate(); app.launchArguments = []; app.launch()
        XCTAssertTrue(statusValue?.contains("step 1 of 5") == true)
    }

    func testMalformedStoredStateReturnsToEmptyJourney() {
        app.launchArguments = ["-inject-malformed-multiples-state"]
        app.launch()
        XCTAssertEqual(statusValue, "Enter a multiplier to begin.")
    }

    func testRotationAndLocalizationKeepControlsUsable() {
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.textFields["multiples.input"].waitForExistence(timeout: 2))
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.buttons["multiples.start"].isHittable)
    }
}
