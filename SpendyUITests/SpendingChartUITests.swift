import XCTest

final class SpendingChartUITests: XCTestCase {
    @MainActor private func launch(light: Bool = false, largeText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "charts"
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        if light { app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = "light" }
        if largeText { app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.staticTexts["home-spending-total"].waitForExistence(timeout: 15))
        return app
    }
    @MainActor private func button(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        let matches = app.buttons.matching(identifier: identifier)
        return matches.allElementsBoundByIndex.first { $0.isHittable } ?? matches.firstMatch
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    @MainActor func testAnalyticsInfoLegendsAndStreak() {
        let app = launch(light: true)
        app.buttons["Analytics and statistics"].tap()
        button(app, "About spending").tap()
        XCTAssertTrue(app.staticTexts["Spendy insights"].waitForExistence(timeout: 5))
        capture(app, "Analytics insights in info")
        button(app, "Done").tap()
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.99, dy: 0.85)).press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.99, dy: 0.3)))
        XCTAssertTrue(app.staticTexts["Bar length = amount spent · percentages = share of recorded spending"].exists)
        capture(app, "Category spending chart")
        for _ in 0..<4 {
            if app.staticTexts["Outlined date · spending recorded"].isHittable { break }
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.99, dy: 0.85)).press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.99, dy: 0.3)))
        }
        XCTAssertTrue(app.staticTexts["Outlined date · spending recorded"].exists)
        XCTAssertTrue(app.staticTexts["Outlined date · spending recorded"].exists)
        capture(app, "Redesigned streak calendar")
    }
    @MainActor func testHomeChartStyleInfoAndPrivacy() {
        let app = launch()
        XCTAssertTrue(app.staticTexts["home-spending-total"].label.contains("1,200"))
        XCTAssertTrue(app.staticTexts["home-spending-comparison"].label.contains("300"))
        capture(app, "Home spending dark")
        let style = app.buttons["Spending chart style"]
        let previous = style.value as? String
        style.tap()
        XCTAssertNotEqual(style.value as? String, previous)
        capture(app, "Home spending alternate style")
        style.tap()
        XCTAssertEqual(style.value as? String, previous)
        button(app, "About spending").tap()
        XCTAssertTrue(app.navigationBars["About spending"].waitForExistence(timeout: 5))
        capture(app, "Spending explanation")
        button(app, "Done").tap()
        app.buttons["More actions"].tap()
        app.buttons["Hide Amounts"].tap()
        XCTAssertTrue(app.staticTexts["home-spending-total"].label.contains("hidden"))
        XCTAssertFalse(app.staticTexts["home-spending-comparison"].exists)
        XCTAssertFalse(app.buttons["home-spending-insights"].exists)
        capture(app, "Home spending privacy")
    }
    @MainActor func testDrawerFiltersDoNotChangeHomeSpending() {
        let app = launch()
        let original = app.staticTexts["home-spending-total"].label
        app.buttons["Expand recent activity"].tap()
        let filters = app.scrollViews["transactionFilters"]
        filters.swipeLeft()
        app.buttons["All Types"].tap()
        app.buttons["Income"].tap()
        app.buttons["Collapse recent activity"].tap()
        XCTAssertEqual(app.staticTexts["home-spending-total"].label, original)
        XCTAssertTrue(original.contains("1,200"))
    }
    @MainActor func testAnalyticsRecordedTotalsAndDrillThrough() {
        let app = launch(light: true)
        capture(app, "Home spending light")
        app.buttons["Analytics and statistics"].tap()
        let transactions = button(app, "spending-transactions")
        XCTAssertTrue(transactions.waitForExistence(timeout: 5))
        if !transactions.isHittable { app.swipeUp() }
        capture(app, "Analytics spending light")
        transactions.tap()
        XCTAssertTrue(app.navigationBars["Spending transactions"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Chart groceries"].exists)
        XCTAssertTrue(app.staticTexts["Chart dining"].exists)
        XCTAssertFalse(app.staticTexts["Future chart expense"].exists)
        XCTAssertFalse(app.staticTexts["Chart salary"].exists)
        capture(app, "Matching spending transactions")
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "spending-transaction-")).firstMatch.tap()
        XCTAssertTrue(app.buttons["Edit Transaction"].waitForExistence(timeout: 5))
    }
    @MainActor func testChartSelectionAndScopedInsights() {
        let app = launch()
        let original = app.staticTexts["home-spending-total"].label
        let chart = app.otherElements.matching(identifier: "spending-chart").allElementsBoundByIndex.first { $0.isHittable }
            ?? app.otherElements["spending-chart"].firstMatch
        XCTAssertTrue(chart.exists)
        chart.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.45)).tap()
        XCTAssertNotEqual(app.staticTexts["home-spending-total"].label, original)
        capture(app, "Selected spending month")
        button(app, "Reset chart selection").tap()
        XCTAssertEqual(app.staticTexts["home-spending-total"].label, original)
        button(app, "All Accounts").tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Cash (")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["home-spending-total"].label.contains("840"))
        let insights = button(app, "home-spending-insights")
        if !insights.isHittable { app.scrollViews["home-spending-canvas"].firstMatch.swipeUp() }
        insights.tap()
        button(app, "spending-transactions").tap()
        XCTAssertTrue(app.staticTexts["Chart groceries"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Chart dining"].exists)
    }

    @MainActor func testLargeTextHomeCanReachInsights() {
        let app = launch(largeText: true)
        let insights = button(app, "home-spending-insights")
        let canvas = app.scrollViews["home-spending-canvas"].firstMatch
        for _ in 0..<5 {
            if insights.isHittable && insights.frame.maxY < canvas.frame.maxY - 8 { break }
            canvas.swipeUp()
        }
        XCTAssertTrue(insights.isHittable)
        capture(app, "Home spending large text scrolled")
        insights.tap()
        XCTAssertTrue(app.staticTexts["Recorded spending"].waitForExistence(timeout: 5))
    }
}
