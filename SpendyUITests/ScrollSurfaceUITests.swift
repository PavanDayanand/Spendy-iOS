import XCTest

final class ScrollSurfaceUITests: XCTestCase {
    @MainActor func testHomeSummaryDragKeepsHeaderAndFittingSummaryStationary() throws {
        let app = launch(light: false)
        guard app.frame.width < 600 && app.frame.height > 750 else {
            throw XCTSkip("Run the fitting Home summary check on a tall compact iPhone.")
        }
        let profile = app.buttons["home-profile"]
        let amount = app.staticTexts["home-spending-total"]
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        let profileBefore = profile.frame
        let amountBefore = amount.frame
        capture(app, "Home before summary drag")
        amount.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.6,
                     thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.17)))
        XCTAssertEqual(profile.frame.minY, profileBefore.minY, accuracy: 2,
                       "Dragging the summary must not move the profile toolbar.")
        XCTAssertEqual(amount.frame.minY, amountBefore.minY, accuracy: 2,
                       "A summary that fits should remain stationary when dragged.")
        XCTAssertTrue(profile.isHittable)
        XCTAssertTrue(app.buttons["Analytics and statistics"].isHittable)
        capture(app, "Home after summary drag")
    }

    @MainActor func testScrollEdgesAndNavigationDark() { verifySurfaces(light: false) }
    @MainActor func testScrollEdgesAndNavigationLight() { verifySurfaces(light: true) }

    @MainActor private func verifySurfaces(light: Bool) {
        continueAfterFailure = false
        let app = launch(light: light, mode: "website-screenshots")
        let suffix = light ? "light" : "dark"
        app.buttons["Analytics and statistics"].tap()
        XCTAssertTrue(app.navigationBars["Analytics"].waitForExistence(timeout: 5))
        app.scrollViews["analytics-scroll"].swipeUp()
        capture(app, "Analytics soft edge \(suffix)")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 5))
        app.buttons["More actions"].tap()
        app.buttons["Budget"].tap()
        XCTAssertTrue(app.navigationBars["Budget"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["budget-options"].exists)
        app.buttons["Show budget calculator"].tap()
        app.scrollViews.firstMatch.swipeUp()
        XCTAssertTrue(app.navigationBars.buttons.element(boundBy: 0).isHittable)
        capture(app, "Budget soft edge \(suffix)")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 5))
        let dockReady = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hittable == true"), object: app.buttons["spendy-dock-subscriptions"])
        XCTAssertEqual(XCTWaiter.wait(for: [dockReady], timeout: 5), .completed)
        app.buttons["spendy-dock-subscriptions"].tap()
        XCTAssertTrue(app.buttons["subscriptions-add"].waitForExistence(timeout: 5))
        app.scrollViews.firstMatch.swipeUp()
        XCTAssertTrue(app.buttons["subscriptions-add"].isHittable)
        capture(app, "Subscriptions soft edge \(suffix)")
        app.buttons["spendy-dock-home"].tap()
        app.buttons["home-profile"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        app.scrollViews.firstMatch.swipeUp()
        XCTAssertTrue(app.buttons["Close"].firstMatch.isHittable)
        capture(app, "Settings soft edge \(suffix)")
        let about = app.buttons["settings-help-about"]
        for _ in 0..<4 {
            if about.isHittable { break }
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(about.isHittable)
        about.tap()
        XCTAssertTrue(app.navigationBars["Help & about"].waitForExistence(timeout: 5))
        app.scrollViews.firstMatch.swipeUp()
        capture(app, "Settings pushed page soft edge \(suffix)")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        app.buttons["Close"].firstMatch.tap()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 5))
    }

    @MainActor private func launch(light: Bool, mode: String = "charts") -> XCUIApplication {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = mode
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = light ? "light" : "dark"
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL"]
        app.launch()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 15))
        return app
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
