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
    @MainActor func testViewAllSpendingBreakdown() {
        let app = launch(light: true)
        app.buttons["Analytics and statistics"].tap()
        let all = button(app, "expand-spending-breakdown")
        for _ in 0..<3 {
            if all.isHittable { break }
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.99, dy: 0.85)).press(forDuration: 0.05,
                thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.99, dy: 0.3)))
        }
        all.tap()
        XCTAssertTrue(app.staticTexts["Spending by Category"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["breakdown-groceries"].exists)
        XCTAssertFalse(app.buttons["breakdown-show-transactions"].exists)
        capture(app, "Full spending breakdown")
        button(app, "breakdown-menu").tap()
        button(app, "Show chart").tap()
        button(app, "breakdown-menu").tap()
        button(app, "Show chart").tap()
        button(app, "breakdown-menu").tap()
        button(app, "breakdown-filter").tap()
        XCTAssertTrue(app.navigationBars["Categories"].waitForExistence(timeout: 5))
        button(app, "Clear all").tap()
        let search = app.textFields["Search categories"]
        search.tap()
        search.typeText("Grocer\n")
        XCTAssertTrue(app.buttons["filter-category-groceries"].exists)
        XCTAssertFalse(app.buttons["filter-category-food"].exists)
        button(app, "filter-category-groceries").tap()
        XCTAssertEqual(button(app, "filter-category-groceries").value as? String, "Selected")
        button(app, "Done").tap()
        XCTAssertTrue(app.staticTexts["breakdown-total"].label.contains("600"))
        XCTAssertEqual(button(app, "breakdown-menu").value as? String, "1 selected")
        XCTAssertFalse(app.buttons.matching(identifier: "breakdown-food").allElementsBoundByIndex.contains { $0.isHittable })
        button(app, "breakdown-groceries").tap()
        XCTAssertTrue(app.staticTexts["entity-spending-total"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["entity-spending-total"].firstMatch.label.contains("600"))
        button(app, "Back").tap()
        XCTAssertTrue(app.staticTexts["breakdown-total"].label.contains("600"))
        capture(app, "Filtered category spending")
        button(app, "breakdown-menu").tap()
        XCTAssertTrue(button(app, "breakdown-filter").label.contains("1 selected"))
        button(app, "breakdown-reset-filters").tap()
        XCTAssertTrue(app.staticTexts["breakdown-total"].label.contains("1,200"))
        XCTAssertEqual(button(app, "breakdown-menu").value as? String, "All selected")
        button(app, "Back").tap()
        XCTAssertFalse(button(app, "spending-transactions").exists)
    }
    @MainActor func testAnalyticsInfoLegendsAndStreak() {
        let app = launch(light: true)
        app.buttons["Analytics and statistics"].tap()
        button(app, "open-spendy-insights").tap()
        XCTAssertTrue(app.navigationBars["Spendy insights"].waitForExistence(timeout: 5))
        capture(app, "Analytics insights in info")
        button(app, "Done").tap()
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.99, dy: 0.85)).press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.99, dy: 0.3)))
        XCTAssertTrue(app.staticTexts["Category spending"].exists)
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
        capture(app, "Three collapsed recent transactions")
        app.buttons["Expand recent activity"].tap()
        capture(app, "Recent activity translucent pinned controls")
        let viewport = app.scrollViews["homeActivityViewport"].firstMatch
        viewport.swipeUp()
        capture(app, "Recent activity scrolled behind controls and dock")
        button(app, "Collapse recent activity").tap()
        XCTAssertTrue(button(app, "Expand recent activity").waitForExistence(timeout: 5))
        button(app, "Expand recent activity").tap()
        let filters = app.scrollViews["transactionFilters"]
        filters.swipeLeft()
        app.buttons["All Types"].tap()
        app.buttons["Income"].tap()
        app.buttons["Collapse recent activity"].tap()
        XCTAssertEqual(app.staticTexts["home-spending-total"].label, original)
        XCTAssertTrue(original.contains("1,200"))
        button(app, "See all transactions").tap()
        XCTAssertTrue(app.staticTexts["All Transactions"].firstMatch.waitForExistence(timeout: 5))
        let allViewport = app.scrollViews["allTransactionsViewport"].firstMatch
        allViewport.swipeUp()
        capture(app, "All transactions translucent pinned header after scrolling")
        button(app, "Categories").tap()
        XCTAssertTrue(app.navigationBars["Categories"].waitForExistence(timeout: 5))
    }
    @MainActor func testTransactionEmptySearchCanRecover() {
        let app = launch()
        button(app, "See all transactions").tap()
        XCTAssertTrue(app.staticTexts["All Transactions"].waitForExistence(timeout: 5))
        let search = app.textFields["Search transactions"]
        search.tap()
        search.typeText("unmatched-transaction-query")
        XCTAssertTrue(app.staticTexts["No matching transactions"].waitForExistence(timeout: 5))
        button(app, "Clear search and filters").tap()
        XCTAssertTrue(app.staticTexts["Chart groceries"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["No matching transactions"].exists)
        capture(app, "Transaction search recovered")
    }
    @MainActor func testAnalyticsRecordedTotalsAndDrillThrough() {
        let app = launch()
        app.buttons["Analytics and statistics"].tap()
        let total = app.staticTexts["analytics-spending-total"].firstMatch
        XCTAssertTrue(total.waitForExistence(timeout: 5))
        XCTAssertTrue(total.label.contains("1,200"))
        XCTAssertFalse(button(app, "spending-transactions").exists)
        XCTAssertFalse(app.staticTexts["Show transactions"].exists)
        capture(app, "Compact analytics spending")
        XCTAssertFalse(button(app, "About spending").exists)
        let chart = app.otherElements.matching(identifier: "spending-chart").allElementsBoundByIndex.first { $0.isHittable }!
        chart.coordinate(withNormalizedOffset: CGVector(dx: 0.12, dy: 0.5)).press(forDuration: 0.5,
            thenDragTo: chart.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.5)))
        XCTAssertTrue(total.label.contains("1,200"))
        XCTAssertFalse(button(app, "Reset chart selection").exists)
        button(app, "expand-spending-breakdown").tap()
        XCTAssertTrue(app.staticTexts["Spending by Category"].waitForExistence(timeout: 5))
    }
    @MainActor func testChartSelectionAndScopedInsights() {
        let app = launch()
        let original = app.staticTexts["home-spending-total"].label
        let chart = app.otherElements.matching(identifier: "spending-chart").allElementsBoundByIndex.first { $0.isHittable }
            ?? app.otherElements["spending-chart"].firstMatch
        XCTAssertTrue(chart.exists)
        chart.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.45)).tap()
        XCTAssertEqual(app.staticTexts["home-spending-total"].label, original)
        chart.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.45)).press(forDuration: 0.5,
            thenDragTo: chart.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.45)))
        XCTAssertEqual(app.staticTexts["home-spending-total"].label, original)
        XCTAssertFalse(button(app, "Reset chart selection").exists)
        capture(app, "Spending restored after hold preview")
        button(app, "All Accounts").tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Cash (")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["home-spending-total"].label.contains("840"))
        let insights = button(app, "home-spending-insights")
        if !insights.isHittable { app.scrollViews["home-spending-canvas"].firstMatch.swipeUp() }
        insights.tap()
        XCTAssertTrue(app.navigationBars["Spendy insights"].waitForExistence(timeout: 5))
        let details = button(app, "View spending details")
        if !details.isHittable { app.swipeUp() }
        details.tap()
        XCTAssertTrue(app.staticTexts["analytics-spending-total"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["analytics-spending-total"].firstMatch.label.contains("840"))
        XCTAssertFalse(button(app, "spending-transactions").exists)
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
        XCTAssertTrue(app.navigationBars["Spendy insights"].waitForExistence(timeout: 5))
    }
}
