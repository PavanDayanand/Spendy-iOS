import XCTest

/// These checks exercise resizing and native navigation, not a simulated Duo hinge.
final class AdaptiveLayoutUITests: XCTestCase {
    @MainActor private func launch(systemNavigation: Bool = false, landscape: Bool = false) -> XCUIApplication {
        XCUIDevice.shared.orientation = landscape ? .landscapeLeft : .portrait
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "charts"
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        app.launchEnvironment["SPENDY_UI_TEST_RECEIPT_INTRO"] = "seen"
        if systemNavigation { app.launchEnvironment["SPENDY_UI_TEST_SYSTEM_NAVIGATION"] = "1" }
        app.launch()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 15))
        return app
    }

    @MainActor func testCompactDockDoesNotRenderNativeTabs() throws {
        continueAfterFailure = false
        let app = launch()
        guard app.frame.width < 600 else { throw XCTSkip("Run the custom dock check on a compact iPhone.") }
        XCTAssertEqual(app.tabBars.count, 0, "The native tab bar must be hidden while the custom dock is active.")
        XCTAssertTrue(app.buttons["Add Transaction"].isHittable)
        capture(app, "Compact Home has only the custom dock")
        app.buttons["Subscriptions"].tap()
        XCTAssertTrue(app.buttons["subscriptions-add"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.tabBars.count, 0, "Switching tabs must not restore the native bar.")
        app.buttons["Home"].tap()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.tabBars.count, 0)
    }

    @MainActor func testSystemNavigationKeepsDestinationsAndReceiptActionsReachable() {
        let app = launch(systemNavigation: true)
        XCTAssertFalse(app.buttons["spendy-dock-home"].exists,
                       "Native navigation must not also render the custom dock.")
        XCTAssertTrue(tab("Subscriptions", in: app).waitForExistence(timeout: 5))
        tab("Subscriptions", in: app).tap()
        XCTAssertTrue(app.buttons["subscriptions-add"].waitForExistence(timeout: 5))
        tab("Stats", in: app).tap()
        XCTAssertTrue(app.scrollViews["analytics-scroll"].waitForExistence(timeout: 5))
        tab("Home", in: app).tap()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 5))
        if !app.buttons["Scan receipt"].isHittable { app.buttons["More"].tap() }
        app.buttons["Scan receipt"].tap()
        XCTAssertTrue(app.buttons["Choose photo"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Scan with camera"].exists)
        if app.buttons["Cancel"].exists { app.buttons["Cancel"].tap() }
        else { app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.95)).tap() }
        capture(app, "Adaptive native navigation")
    }

    @MainActor func testTransactionDraftSurvivesRotationAndSaveStaysReachable() {
        defer { XCUIDevice.shared.orientation = .portrait }
        let app = launch()
        if !app.buttons["Add Transaction"].isHittable { app.buttons["More"].tap() }
        app.buttons["Add Transaction"].tap()
        let digit = app.buttons["5"]
        XCTAssertTrue(digit.waitForExistence(timeout: 5))
        digit.tap()
        XCTAssertTrue(app.staticTexts["5"].exists)
        if app.frame.width >= 600 {
            XCTAssertGreaterThan(digit.frame.minY, app.staticTexts["5"].firstMatch.frame.maxY,
                                 "Portrait entry should keep the amount above the keypad.")
            capture(app, "Open portrait single-column entry")
        }
        XCUIDevice.shared.orientation = .landscapeLeft
        let landscape = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in app.frame.width > app.frame.height }, object: app)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 8), .completed)
        let save = app.buttons["Save"]
        for _ in 0..<5 {
            if save.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(save.isHittable)
        XCTAssertTrue(save.isEnabled)
        XCTAssertTrue(app.frame.contains(save.frame), "Save must fit inside the resized app viewport.")
        capture(app, "Short-height amount entry")
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.staticTexts["5"].waitForExistence(timeout: 5))
        XCTAssertTrue(save.isEnabled)
        // Exercise the action after a second resize, rather than relying only on geometry.
        XCUIDevice.shared.orientation = .landscapeLeft
        let resized = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in app.frame.width > app.frame.height }, object: app)
        XCTAssertEqual(XCTWaiter.wait(for: [resized], timeout: 8), .completed)
        for _ in 0..<5 {
            if save.isHittable { break }
            app.swipeUp()
        }
        save.tap()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 5))
    }

    @MainActor func testWideHomeKeepsActivityAndSummaryInSeparatePanes() throws {
        let app = launch()
        guard app.frame.width >= 600 else { throw XCTSkip("Run this check on a regular-width simulator.") }
        defer { XCUIDevice.shared.orientation = .portrait }
        let preview = app.descendants(matching: .any).matching(identifier: "home-activity-preview").firstMatch
        XCTAssertTrue(preview.waitForExistence(timeout: 5))
        XCTAssertFalse(app.scrollViews["homeActivityViewport"].exists,
                       "Open portrait should have one continuous Home scroll, not nested half-height panes.")
        capture(app, "Open portrait continuous Home")
        XCUIDevice.shared.orientation = .landscapeLeft
        let landscape = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in app.frame.width > app.frame.height }, object: app)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 8), .completed)
        let activity = app.scrollViews["homeActivityViewport"]
        let summary = app.scrollViews["home-spending-canvas"]
        XCTAssertTrue(activity.waitForExistence(timeout: 5))
        XCTAssertTrue(summary.exists)
        XCTAssertLessThanOrEqual(summary.frame.maxX, activity.frame.minX + 1)
        XCTAssertTrue(app.buttons["See all transactions"].isHittable)
        capture(app, "Open landscape adjacent Home panes")
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(preview.waitForExistence(timeout: 5))
    }

    @MainActor func testCompactNativeHomeUsesOneScrollAndThreeRecentRows() throws {
        let app = launch(systemNavigation: true)
        guard app.frame.width < 600 else { throw XCTSkip("Run the compact flow check on an iPhone simulator.") }
        XCTAssertTrue(app.scrollViews["home-adaptive-scroll"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.scrollViews["homeActivityViewport"].exists)
        let rows = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "home-activity-transaction-"))
        XCTAssertEqual(rows.count, 3)
        capture(app, "Compact Home recent activity")
    }

    @MainActor func testLandscapePanesFitTheVisibleViewport() throws {
        defer { XCUIDevice.shared.orientation = .portrait }
        let app = launch(landscape: true)
        guard app.frame.width >= 1000 else { throw XCTSkip("Run on the regular-width landscape simulator.") }
        let summary = app.scrollViews["home-spending-canvas"]
        let activity = app.scrollViews["homeActivityViewport"]
        XCTAssertTrue(summary.waitForExistence(timeout: 5))
        XCTAssertTrue(activity.exists)
        XCTAssertTrue(app.frame.contains(summary.frame))
        XCTAssertTrue(app.frame.contains(activity.frame))
        capture(app, "Landscape Home stable initial layout")
    }

    @MainActor func testOnboardingRemainsScrollableInShortLandscape() {
        defer { XCUIDevice.shared.orientation = .portrait }
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "standard"
        app.launchArguments = ["--onboarding", "--onboarding-step=0"]
        app.launch()
        let next = app.buttons["Get started"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        XCTAssertTrue(next.isHittable)
        XCTAssertTrue(app.scrollViews.firstMatch.exists)
        capture(app, "Short-height onboarding")
        next.tap()
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5))
    }

    @MainActor private func tab(_ title: String, in app: XCUIApplication) -> XCUIElement {
        // iPad's floating native tabs can be exposed as cells rather than a TabBar.
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", title)).firstMatch
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
