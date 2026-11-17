//
//  DinojaUITests.swift
//  DinojaUITests
//

import XCTest

@MainActor
final class DinojaUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testLandingScreenShowsTitleAndStartButton() {
        XCTAssertTrue(app.images["Dinoja"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Start Game"].exists)
    }

    func testStartingTheGameShowsTheHUD() {
        app.buttons["Start Game"].tap()

        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(labelContains: "Score").firstMatch.exists)
        XCTAssertTrue(app.images["3 lives left"].exists)
    }

    func testPauseHidesTheGameAndContinueResumes() {
        app.buttons["Start Game"].tap()
        let pause = app.buttons["Pause"]
        XCTAssertTrue(pause.waitForExistence(timeout: 5))

        pause.tap()

        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        XCTAssertFalse(pause.exists, "The pause button hides while paused")
        // Score and hearts stay visible on the pause screen.
        XCTAssertTrue(app.staticTexts.matching(labelContains: "Score").firstMatch.exists)
        XCTAssertTrue(app.images.matching(labelContains: "lives left").firstMatch.exists)

        continueButton.tap()

        XCTAssertTrue(pause.waitForExistence(timeout: 5))
        XCTAssertFalse(continueButton.exists)
    }

    func testLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

private extension XCUIElementQuery {
    func matching(labelContains text: String) -> XCUIElementQuery {
        matching(NSPredicate(format: "label CONTAINS %@", text))
    }
}
