import XCTest

final class AnalyticsBudgetUITests: XCTestCase {
    @MainActor func testActiveBudgetDark() { verifySummary(active: true, light: false) }
    @MainActor func testInactiveBudgetLight() { verifySummary(active: false, light: true) }
    @MainActor func testActiveBudgetLargeText() { verifySummary(active: true, light: false, largeText: true) }

    @MainActor func testCategorySectorsLight() {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "charts"
        app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = "light"
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["Analytics and statistics"].waitForExistence(timeout: 15))
        app.buttons["Analytics and statistics"].tap()
        let scroll = app.scrollViews["analytics-scroll"].firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 5))
        let all = app.buttons["expand-spending-breakdown"].firstMatch
        for _ in 0..<6 {
            if all.isHittable { break }
            scroll.swipeUp()
        }
        all.tap()
        let chart = app.descendants(matching: .any)["breakdown-spending-chart"].firstMatch
        if !chart.exists {
            app.buttons["breakdown-menu"].firstMatch.tap()
            app.buttons["breakdown-chart-toggle"].firstMatch.tap()
        }
        XCTAssertTrue(chart.waitForExistence(timeout: 5))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Native category sectors light"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.buttons["analytics-stack-back"].firstMatch.tap()

    }

    @MainActor private func verifySummary(active: Bool, light: Bool, largeText: Bool = false) {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = active ? "insights" : "home-attention-single"
        app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = light ? "light" : "dark"
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        if largeText {
            app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        XCTAssertTrue(app.buttons["Analytics and statistics"].waitForExistence(timeout: 15))
        app.buttons["Analytics and statistics"].tap()
        var scroll: XCUIElement {
            let matches = app.scrollViews.matching(identifier: "analytics-scroll")
            return matches.allElementsBoundByIndex.first { $0.isHittable } ?? matches.firstMatch
        }
        XCTAssertTrue(scroll.waitForExistence(timeout: 5))
        var summary: XCUIElement {
            let matches = app.buttons.matching(identifier: "analytics-budget-summary")
            return matches.allElementsBoundByIndex.first { $0.isHittable } ?? matches.firstMatch
        }
        // At accessibility sizes the chart fills the viewport; scroll along
        // the outer margin so its hold-to-preview gesture is not the target.
        func advanceScroll() {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.85))
                .press(forDuration: 0.01,
                       thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.3)),
                       withVelocity: .fast, thenHoldForDuration: 0)
        }
        for _ in 0..<16 {
            if summary.isHittable { break }
            advanceScroll()
        }
        XCTAssertTrue(summary.isHittable)
        advanceScroll()
        advanceScroll()
        XCTAssertLessThan(scroll.frame.maxY - summary.frame.maxY, 85, "No oversized empty tail after the budget")
        XCTAssertTrue(summary.label.contains(active ? "All accounts" : "Set a spending limit"))
        if active { XCTAssertTrue(summary.label.contains("over budget")) }
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Analytics budget \(active ? "active" : "inactive") \(largeText ? "large text" : light ? "light" : "dark")"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        summary.tap()
        let title = app.staticTexts["analytics-stack-title"].firstMatch
        let opened = expectation(for: NSPredicate(format: "label == %@", "Budget"), evaluatedWith: title)
        wait(for: [opened], timeout: 5)
        if active {
            let remaining = app.descendants(matching: .any)["budget-remaining-amount"].firstMatch
            XCTAssertTrue(remaining.waitForExistence(timeout: 5))
            XCTAssertTrue(remaining.label.contains("over budget"))
            let gauge = XCTAttachment(screenshot: app.screenshot())
            gauge.name = "Budget open ring \(largeText ? "large text" : light ? "light" : "dark")"
            gauge.lifetime = .keepAlways
            add(gauge)
        }
        app.buttons["analytics-stack-back"].tap()
        let returned = expectation(for: NSPredicate(format: "label == %@", "Analytics"), evaluatedWith: title)
        wait(for: [returned], timeout: 5)
        XCTAssertTrue(summary.isHittable)
    }
}
