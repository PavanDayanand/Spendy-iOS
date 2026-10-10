import XCTest

final class SpendyUITests: XCTestCase {
    @MainActor private func launch(_ mode: String = "standard", largeText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = mode
        if largeText { app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        return app
    }

    @MainActor func testRecoveryScreenRestoresPreservedLedger() {
        let app = launch("recovery")
        XCTAssertTrue(app.staticTexts["Saved Data Needs Attention"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Import a Backup"].exists)
        app.buttons["Restore Last Backup"].tap()
        XCTAssertTrue(app.buttons["See all transactions"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Readiness expense")).firstMatch.exists)
    }

    @MainActor func testTransactionDetailsAndHorizontalFilters() {
        let app = launch()
        XCTAssertTrue(app.buttons["Expand recent activity"].waitForExistence(timeout: 10))
        app.buttons["Expand recent activity"].tap()
        let filters = app.scrollViews.matching(identifier: "transactionFilters").firstMatch
        XCTAssertTrue(filters.waitForExistence(timeout: 5))
        filters.swipeLeft()
        XCTAssertTrue(app.buttons["All Types"].isHittable)
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Readiness expense")).firstMatch.tap()
        XCTAssertTrue(app.buttons["Edit Transaction"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Readiness expense"].exists)
    }

    @MainActor func testRecoveryAtLargestTextSize() {
        let app = launch("recovery", largeText: true)
        XCTAssertTrue(app.buttons["Restore Last Backup"].waitForExistence(timeout: 10))
        if !app.buttons["Restore Last Backup"].isHittable { app.swipeUp() }
        XCTAssertTrue(app.buttons["Restore Last Backup"].isHittable)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Recovery with largest accessibility text"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
    @MainActor func testHomeAccessibilityTargetsAndDescriptions() throws {
        let app = launch()
        XCTAssertTrue(app.buttons["See all transactions"].waitForExistence(timeout: 10))
        try app.performAccessibilityAudit(for: [.hitRegion, .sufficientElementDescription]) { issue in
            print("Accessibility audit: \(issue.detailedDescription) — \(issue.element?.debugDescription ?? "unknown element")")
            return false
        }
    }

}
