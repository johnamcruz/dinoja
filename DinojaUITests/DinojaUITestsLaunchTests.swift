//
//  DinojaUITestsLaunchTests.swift
//  DinojaUITests
//
//  Created by John M Cruz on 4/30/23.
//

import XCTest

@MainActor
final class DinojaUITestsLaunchTests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testLaunch() {
        let app = XCUIApplication()
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
