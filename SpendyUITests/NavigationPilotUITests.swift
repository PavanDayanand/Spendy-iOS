import XCTest

final class NavigationPilotUITests: XCTestCase {
    @MainActor func testHomeTransactionsReturnDark() {
        verifyPilot(light: false)
    }

    @MainActor func testHomeTransactionsReturnLight() {
        verifyPilot(light: true)
    }

    @MainActor func testHomeTransactionsLargeText() {
        verifyPilot(light: true, largeText: true)
    }

    @MainActor private func verifyPilot(light: Bool, largeText: Bool = false) {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "charts"
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = light ? "light" : "dark"
        if largeText {
            app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 15))
        capture(app, "Home header")
        let seeAll = app.buttons["See all transactions"]
        XCTAssertTrue(seeAll.waitForExistence(timeout: 5))
        seeAll.tap()

        let back = app.buttons["home-transactions-back"]
        let filters = app.buttons["home-transactions-filters"]
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        XCTAssertTrue(back.isHittable)
        XCTAssertTrue(filters.isHittable)
        XCTAssertEqual(filters.value as? String, "Collapsed")
        XCTAssertFalse(app.buttons["home-profile"].exists)
        XCTAssertFalse(app.buttons["Subscriptions"].isHittable)
        capture(app, "Transactions compact header")

        filters.tap()
        XCTAssertEqual(filters.value as? String, "Expanded")
        XCTAssertTrue(app.descendants(matching: .any)["transaction-filters"].exists)
        capture(app, "Transactions expanded filters")
        filters.tap()
        XCTAssertEqual(filters.value as? String, "Collapsed")
        XCTAssertFalse(app.descendants(matching: .any)["transaction-filters"].exists)

        let search = app.textFields["Search transactions"]
        search.tap()
        search.typeText("no matching purchase")
        XCTAssertTrue(app.staticTexts["No matching transactions"].waitForExistence(timeout: 5))
        app.buttons["Clear search"].tap()
        XCTAssertTrue(back.isHittable)

        // A short edge swipe should cancel and leave the destination usable.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
            .press(forDuration: 0.1,
                   thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.14, dy: 0.5)),
                   withVelocity: .slow, thenHoldForDuration: 0.6)
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        XCTAssertTrue(back.isHittable)
        back.tap()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Analytics and statistics"].isHittable)
        XCTAssertTrue(app.buttons["Subscriptions"].isHittable)
        capture(app, "Home restored after Back")

        // Re-entry starts compact, and completing an edge swipe returns Home.
        seeAll.tap()
        XCTAssertTrue(filters.waitForExistence(timeout: 5))
        XCTAssertEqual(filters.value as? String, "Collapsed")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
            .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5)))
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Analytics and statistics"].isHittable)
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
