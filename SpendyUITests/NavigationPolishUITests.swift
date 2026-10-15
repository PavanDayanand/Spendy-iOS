import XCTest

final class NavigationPolishUITests: XCTestCase {
    @MainActor private func launch(light: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "charts"
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = light ? "light" : "dark"
        app.launch()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 15))
        return app
    }

    @MainActor private func button(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        let matches = app.buttons.matching(identifier: id)
        return matches.allElementsBoundByIndex.first { $0.isHittable } ?? matches.firstMatch
    }

    @MainActor private func title(_ app: XCUIApplication) -> XCUIElement {
        let matches = app.staticTexts.matching(identifier: "analytics-stack-title")
        return matches.allElementsBoundByIndex.first { $0.isHittable } ?? matches.firstMatch
    }

    @MainActor func testAnalyticsReusesBackForCategoryAndReturns() {
        let app = launch()
        app.buttons["Analytics and statistics"].tap()
        let back = button(app, "analytics-stack-back")
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        XCTAssertEqual(title(app).label, "Analytics")
        let originalFrame = back.frame
        let category = button(app, "breakdown-groceries")
        for _ in 0..<3 {
            if category.isHittable { break }
            app.swipeUp()
        }
        category.tap()
        XCTAssertTrue(button(app, "analytics-stack-edit").waitForExistence(timeout: 5))
        XCTAssertEqual(title(app).label, "Groceries")
        XCTAssertEqual(back.frame.minX, originalFrame.minX, accuracy: 1)
        XCTAssertEqual(back.frame.minY, originalFrame.minY, accuracy: 1)
        XCTAssertEqual(app.buttons.matching(identifier: "analytics-stack-back")
            .allElementsBoundByIndex.filter { $0.isHittable }.count, 1)
        let headerBacks = app.buttons.matching(NSPredicate(format: "label == %@", "Back"))
            .allElementsBoundByIndex.filter { $0.isHittable && abs($0.frame.midY - originalFrame.midY) < 20 }
        XCTAssertEqual(headerBacks.count, 1, "Only one Back control may occupy the header")
        capture(app, "Category uses shared Analytics Back")
        button(app, "analytics-stack-edit").tap()
        XCTAssertTrue(button(app, "Close").waitForExistence(timeout: 5))
        button(app, "Close").tap()
        XCTAssertEqual(title(app).label, "Groceries")

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
            .press(forDuration: 0.1,
                   thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.14, dy: 0.5)),
                   withVelocity: .slow, thenHoldForDuration: 0.6)
        XCTAssertEqual(title(app).label, "Groceries")
        capture(app, "Settled category shared header")
        back.tap()
        XCTAssertEqual(title(app).label, "Analytics")
        XCTAssertTrue(button(app, "analytics-filters").isHittable)
        capture(app, "Analytics restored after category")
        back.tap()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 5))
    }

    @MainActor func testExpandedActivityHidesHomeHeader() {
        let app = launch()
        app.buttons["Expand recent activity"].tap()
        XCTAssertTrue(app.buttons["Collapse recent activity"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["home-profile"].exists)
        XCTAssertFalse(app.buttons["Analytics and statistics"].exists)
        XCTAssertFalse(app.buttons["More actions"].exists)
        capture(app, "Expanded Recent Activity without Home controls")
        app.buttons["See all transactions"].tap()
        XCTAssertTrue(app.buttons["home-transactions-back"].waitForExistence(timeout: 5))
        app.buttons["home-transactions-back"].tap()
        XCTAssertFalse(app.buttons["home-profile"].exists)
        app.buttons["Collapse recent activity"].tap()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Analytics and statistics"].isHittable)
    }

    @MainActor func testBudgetImmediatelyDropsHomeControls() {
        let app = launch()
        app.buttons["More actions"].tap()
        button(app, "Budget").tap()
        XCTAssertTrue(app.staticTexts["Budget"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["home-profile"].exists)
        XCTAssertFalse(app.buttons["Analytics and statistics"].exists)
        XCTAssertFalse(app.buttons["More actions"].exists)
        capture(app, "Budget without retained Home capsule")
        button(app, "Back").tap()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 5))
    }

    @MainActor func testSearchEmptyStateIsCenteredAndClears() {
        let app = launch(light: true)
        app.buttons["See all transactions"].tap()
        let search = app.textFields["Search transactions"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Hello")
        let empty = app.staticTexts["No matching transactions"]
        XCTAssertTrue(empty.waitForExistence(timeout: 5))
        XCTAssertEqual(empty.frame.midX, app.frame.midX, accuracy: 3)
        XCTAssertGreaterThan(empty.frame.minY, app.buttons["home-transactions-back"].frame.maxY + 30)
        XCTAssertTrue(app.buttons["Clear search and filters"].isHittable)
        capture(app, "Centered empty search results")
        app.buttons["Clear search and filters"].tap()
        XCTAssertFalse(empty.exists)
        XCTAssertEqual(search.value as? String, "Search transactions")
        app.buttons["home-transactions-back"].tap()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 5))
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
