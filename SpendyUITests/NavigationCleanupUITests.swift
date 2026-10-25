import XCTest

final class NavigationCleanupUITests: XCTestCase {
    @MainActor func testAnalyticsHasNoEmptyActionSurfaceDark() { verifyAnalyticsSurface(light: false) }
    @MainActor func testAnalyticsHasNoEmptyActionSurfaceLight() { verifyAnalyticsSurface(light: true) }

    @MainActor private func verifyAnalyticsSurface(light: Bool) {
        let app = launch(light: light)
        app.buttons["Analytics and statistics"].tap()
        expectHeader("Analytics", in: app)
        XCTAssertFalse(actionSurface(app).exists, "Analytics must not retain an empty Home glass circle")
        capture(app, "Analytics without empty trailing glass \(light ? "light" : "dark")")
        let category = button("breakdown-groceries", in: app)
        for _ in 0..<3 {
            if category.isHittable { break }
            app.swipeUp()
        }
        category.tap()
        expectHeader("Groceries", in: app)
        XCTAssertTrue(actionSurface(app).exists)
        XCTAssertTrue(button("analytics-stack-edit", in: app).isHittable)
        button("analytics-stack-back", in: app).tap()
        expectHeader("Analytics", in: app)
        XCTAssertFalse(actionSurface(app).exists)
        button("analytics-stack-back", in: app).tap()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 5))
        XCTAssertTrue(actionSurface(app).exists)
    }

    @MainActor func testBudgetSharedHeaderEditAndDeleteCancellation() {
        let app = launch(mode: "home-attention")
        app.buttons["More actions"].tap()
        button("Budget", in: app).tap()
        expectHeader("Budget", in: app)
        XCTAssertTrue(actionSurface(app).exists)
        XCTAssertFalse(app.buttons["home-profile"].exists)
        button("budget-options", in: app).tap()
        button("budget-edit", in: app).tap()
        XCTAssertTrue(app.staticTexts["Edit Budget"].waitForExistence(timeout: 5))
        button("Close", in: app).tap()
        expectHeader("Budget", in: app)
        button("budget-options", in: app).tap()
        button("budget-delete", in: app).tap()
        XCTAssertTrue(app.alerts["Delete Budget?"].waitForExistence(timeout: 5))
        app.alerts.buttons["Cancel"].tap()
        expectHeader("Budget", in: app)
        capture(app, "Budget shared header after cancelled deletion")
        button("analytics-stack-back", in: app).tap()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 5))
    }

    @MainActor func testHomeSubscriptionInsightReturnsToSharedHubHeader() {
        let app = launch(mode: "home-attention-single")
        let insights = button("home-priority-insight", in: app)
        if !insights.isHittable { app.scrollViews["home-spending-canvas"].firstMatch.swipeUp() }
        insights.tap()
        XCTAssertTrue(app.navigationBars["Spendy insights"].waitForExistence(timeout: 5))
        let subscription = app.buttons["Explore insight"].firstMatch
        for _ in 0..<3 {
            if subscription.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(subscription.isHittable)
        subscription.tap()
        XCTAssertTrue(button("Close", in: app).waitForExistence(timeout: 5))
        button("Close", in: app).tap()
        expectHeader("Subscriptions", in: app)
        XCTAssertTrue(button("subscriptions-add", in: app).isHittable)
        capture(app, "Subscription hub reuses the Home stack header")
        button("subscriptions-add", in: app).tap()
        XCTAssertTrue(app.staticTexts["New Subscription"].waitForExistence(timeout: 5))
        button("Close", in: app).tap()
        expectHeader("Subscriptions", in: app)
        button("analytics-stack-back", in: app).tap()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 5))
    }

    @MainActor private func launch(mode: String = "charts", light: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = mode
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = light ? "light" : "dark"
        app.launch()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 15))
        return app
    }

    @MainActor private func actionSurface(_ app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "home-shared-action-surface").firstMatch
    }

    @MainActor private func button(_ id: String, in app: XCUIApplication) -> XCUIElement {
        let matches = app.buttons.matching(identifier: id)
        return matches.allElementsBoundByIndex.first { $0.isHittable } ?? matches.firstMatch
    }

    @MainActor private func expectHeader(_ title: String, in app: XCUIApplication) {
        let label = app.staticTexts["analytics-stack-title"].firstMatch
        let match = expectation(for: NSPredicate(format: "label == %@", title), evaluatedWith: label)
        wait(for: [match], timeout: 5)
        let back = button("analytics-stack-back", in: app)
        XCTAssertTrue(back.isHittable)
        let backs = app.buttons.matching(NSPredicate(format: "label == %@", "Back"))
            .allElementsBoundByIndex.filter { $0.isHittable && abs($0.frame.midY - back.frame.midY) < 20 }
        XCTAssertEqual(backs.count, 1)
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
