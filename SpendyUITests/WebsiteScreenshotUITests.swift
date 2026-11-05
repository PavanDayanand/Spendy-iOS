import XCTest

// Manual capture helper; normal test runs must not launch Shortcuts or require capture setup.
final class WebsiteScreenshotUITests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        let environment = ProcessInfo.processInfo.environment
        try XCTSkipUnless(
            environment["SPENDY_CAPTURE_WEBSITE_SCREENS"] == "1"
                || environment["TEST_RUNNER_SPENDY_CAPTURE_WEBSITE_SCREENS"] == "1",
            "Enable website screenshot capture explicitly."
        )
    }

    @MainActor func testCaptureWebsiteScreens() {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "website-screenshots"
        app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = ProcessInfo.processInfo.environment["SPENDY_CAPTURE_APPEARANCE"] ?? ProcessInfo.processInfo.environment["TEST_RUNNER_SPENDY_CAPTURE_APPEARANCE"] ?? "light"
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        app.launchEnvironment["SPENDY_UI_TEST_RECEIPT_INTRO"] = "seen"
        app.launch()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 20))
        capture(app, "website-home")
        app.buttons["Analytics and statistics"].tap()
        XCTAssertTrue(app.scrollViews["analytics-scroll"].waitForExistence(timeout: 10))
        let timeframe = app.buttons.matching(identifier: "Select Timeframe").allElementsBoundByIndex.first { $0.isHittable } ?? app.buttons["Select Timeframe"].firstMatch
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.37, dy: timeframe.frame.midY / app.frame.height)).tap()
        capture(app, "website-analytics")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["Subscriptions"].waitForExistence(timeout: 15))
        app.buttons["Subscriptions"].tap()
        capture(app, "website-subscriptions")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["Add Transaction"].waitForExistence(timeout: 15))
        app.buttons["Add Transaction"].tap()
        app.buttons["1"].tap()
        app.buttons["8"].tap()
        app.buttons["0"].tap()
        capture(app, "website-entry")
        app.terminate()
        app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = "dark"
        app.launch()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 15))
        capture(app, "website-home-dark")
    }

    @MainActor func testCaptureCompletedMonth() {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "website-screenshots"
        app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = ProcessInfo.processInfo.environment["SPENDY_CAPTURE_APPEARANCE"] ?? ProcessInfo.processInfo.environment["TEST_RUNNER_SPENDY_CAPTURE_APPEARANCE"] ?? "light"
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["Analytics and statistics"].waitForExistence(timeout: 15))
        app.buttons["Analytics and statistics"].tap()
        let timeframe = app.buttons.matching(identifier: "Select Timeframe").allElementsBoundByIndex.first { $0.isHittable } ?? app.buttons["Select Timeframe"].firstMatch
        XCTAssertTrue(timeframe.waitForExistence(timeout: 10))
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.37, dy: timeframe.frame.midY / app.frame.height)).tap()
        capture(app, "website-analytics")
    }

    @MainActor func testCaptureSpendingInsights() {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "website-screenshots"
        app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = ProcessInfo.processInfo.environment["SPENDY_CAPTURE_APPEARANCE"] ?? ProcessInfo.processInfo.environment["TEST_RUNNER_SPENDY_CAPTURE_APPEARANCE"] ?? "light"
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        app.launch()
        let insights = app.buttons["home-priority-insight"]
        XCTAssertTrue(insights.waitForExistence(timeout: 20))
        insights.tap()
        XCTAssertTrue(app.navigationBars["Spendy insights"].waitForExistence(timeout: 10))
        // Capture the sheet as opened from Home, without dragging it upward.
        RunLoop.current.run(until: Date().addingTimeInterval(1))
        capture(app, "website-insights")

    }

    @MainActor func testCaptureShortcuts() {
        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        shortcuts.launch()
        if shortcuts.buttons["Continue"].waitForExistence(timeout: 5) { shortcuts.buttons["Continue"].tap() }
        let library = shortcuts.buttons["Library"]
        if library.waitForExistence(timeout: 5) { library.tap() }
        RunLoop.current.run(until: Date().addingTimeInterval(2))
        let spendy = shortcuts.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Spendy")).firstMatch
        if spendy.exists { spendy.tap() }
        RunLoop.current.run(until: Date().addingTimeInterval(2))
        XCTAssertTrue(shortcuts.staticTexts["Add Expense"].waitForExistence(timeout: 10))
        capture(shortcuts, "website-shortcuts")
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        // Let native navigation and chart animations settle before the capture.
        RunLoop.current.run(until: Date().addingTimeInterval(2))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
