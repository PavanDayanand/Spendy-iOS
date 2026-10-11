import XCTest

final class SpendyUITests: XCTestCase {
    @MainActor private func launch(_ mode: String = "standard", largeText: Bool = false, light: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = mode
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        if light { app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = "light" }
        if largeText { app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        return app
    }

    @MainActor func testRemainingCategoriesOpenAndReturnToAnalytics() {
        let app = launch("analytics")
        app.buttons["Analytics and statistics"].tap()
        func visibleButton(_ identifier: String) -> XCUIElement {
            let matches = app.buttons.matching(identifier: identifier)
            return matches.allElementsBoundByIndex.first { $0.isHittable } ?? matches.firstMatch
        }
        var more = visibleButton("expand-spending-breakdown")
        for _ in 0..<4 {
            if more.isHittable { break }
            app.swipeUp()
            more = visibleButton("expand-spending-breakdown")
        }
        XCTAssertTrue(more.waitForExistence(timeout: 5))
        more.tap()
        var remaining = visibleButton("breakdown-coffee")
        for _ in 0..<3 {
            if remaining.isHittable { break }
            app.swipeUp()
            remaining = visibleButton("breakdown-coffee")
        }
        XCTAssertTrue(visibleButton("breakdown-menu").isHittable)
        let headerShot = XCTAttachment(screenshot: app.screenshot())
        headerShot.name = "Category breakdown translucent header while scrolling"
        headerShot.lifetime = .keepAlways
        add(headerShot)
        XCTAssertTrue(remaining.waitForExistence(timeout: 5))
        remaining.tap()
        XCTAssertTrue(visibleButton("Back").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Coffee & Cafés"].exists)
        visibleButton("Back").tap()
        XCTAssertTrue(visibleButton("breakdown-coffee").waitForExistence(timeout: 5))
        let breakdownScroll = app.scrollViews["breakdown-scroll"]
        XCTAssertTrue(breakdownScroll.waitForExistence(timeout: 5))
        for _ in 0..<3 { breakdownScroll.swipeUp() }
        XCTAssertFalse(app.staticTexts["breakdown-total"].isHittable)
        XCTAssertTrue(visibleButton("breakdown-menu").isHittable)
        let scrolledHeaderShot = XCTAttachment(screenshot: app.screenshot())
        scrolledHeaderShot.name = "Category breakdown translucent header after scrolling"
        scrolledHeaderShot.lifetime = .keepAlways
        add(scrolledHeaderShot)
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

    @MainActor func testInsightAndNotificationPreferences() { verifyPreferences(light: false) }
    @MainActor func testInsightAndNotificationPreferencesInLightMode() { verifyPreferences(light: true) }

    @MainActor private func verifyPreferences(light: Bool) {
        let app = launch("analytics", light: light)
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Profile,")).firstMatch.tap()
        XCTAssertTrue(app.buttons["Edit profile"].waitForExistence(timeout: 5))
        let settingsShot = XCTAttachment(screenshot: app.screenshot())
        settingsShot.name = light ? "Settings grey light" : "Settings grey dark"
        settingsShot.lifetime = .keepAlways
        add(settingsShot)
        let insights = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Spendy Insights")).firstMatch
        for _ in 0..<4 {
            if insights.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(insights.waitForExistence(timeout: 5))
        insights.tap()
        let toggle = app.switches["Spendy Insights"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        XCTAssertEqual(toggle.value as? String, "1")
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        XCTAssertTrue(NSPredicate(format: "value == %@", "0").evaluate(with: toggle))
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Spendy Insights preferences"
        shot.lifetime = .keepAlways
        add(shot)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Notifications")).firstMatch.tap()
        XCTAssertTrue(app.switches["Weekly summary"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.switches["Logging reminders"].exists)
        XCTAssertTrue(app.switches["Bill reminders"].exists)
        XCTAssertEqual(app.switches["Weekly summary"].value as? String, "0")
        let notificationShot = XCTAttachment(screenshot: app.screenshot())
        notificationShot.name = "Notification preferences"
        notificationShot.lifetime = .keepAlways
        add(notificationShot)
    }

    @MainActor func testInsightPagerShowsSecondObservationAndReturns() {
        let app = launch("insights")
        app.buttons["Analytics and statistics"].tap()
        let next = app.buttons.matching(identifier: "next-insight").allElementsBoundByIndex.first { $0.isHittable }
        guard let next else { XCTFail("Expected several insight pages"); return }
        let count = Int((next.value as? String ?? "").split(separator: " ").last ?? "0") ?? 0
        XCTAssertTrue((2...5).contains(count))
        XCTAssertEqual(next.value as? String, "Insight 1 of \(count)")
        next.tap()
        XCTAssertEqual(next.value as? String, "Insight 2 of \(count)")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Second insight"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        for _ in 1..<count { next.tap() }
        XCTAssertEqual(next.value as? String, "Insight 1 of \(count)")
    }

    @MainActor func testInsightsAutomaticallyAdvanceEveryThreeSeconds() {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "insights"
        app.launch()
        app.buttons["Analytics and statistics"].tap()
        let next = app.buttons.matching(identifier: "next-insight").firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        let count = Int((next.value as? String ?? "").split(separator: " ").last ?? "0") ?? 0
        XCTAssertTrue((2...5).contains(count))
        next.tap() // Restarts the three-second interval after manual paging.
        let manualPage = next.value as? String ?? ""
        let changed = expectation(for: NSPredicate(format: "value != %@", manualPage), evaluatedWith: next)
        wait(for: [changed], timeout: 5)
        let automaticPage = next.value as? String ?? ""
        let changedAgain = expectation(for: NSPredicate(format: "value != %@", automaticPage), evaluatedWith: next)
        wait(for: [changedAgain], timeout: 5)
    }

    @MainActor func testAccountAnalyticsFromSettingsKeepsGreyAndReturns() {
        let app = launch("analytics")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Profile,")).firstMatch.tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Accounts")).firstMatch.tap()
        for attempt in 0..<3 {
            let account = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Cash, Cash,")).firstMatch
            XCTAssertTrue(account.waitForExistence(timeout: 5))
            account.tap()
            XCTAssertTrue(app.buttons["Edit Cash"].waitForExistence(timeout: 5))
            if attempt == 0 {
                let shot = XCTAttachment(screenshot: app.screenshot())
                shot.name = "Account analytics from Settings grey"
                shot.lifetime = .keepAlways
                add(shot)
            }
            app.navigationBars.buttons.element(boundBy: 0).tap()
            XCTAssertTrue(app.buttons["Add Account"].waitForExistence(timeout: 5))
        }
    }

    @MainActor func testAccountAnalyticsFromAnalyticsKeepsAppBackgroundAndReturns() {
        let app = launch("analytics")
        app.buttons["Analytics and statistics"].tap()
        XCTAssertTrue(app.buttons.matching(identifier: "analytics-filters").firstMatch.waitForExistence(timeout: 5))
        app.buttons.matching(identifier: "analytics-filters").firstMatch.tap()
        app.buttons["Accounts"].tap()
        let row = app.buttons["breakdown-cash"]
        for _ in 0..<5 {
            if row.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.buttons["Edit Cash"].waitForExistence(timeout: 5))
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Account analytics from Analytics black"
        shot.lifetime = .keepAlways
        add(shot)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
    }

    @MainActor func testSettingsCategoryEditorAndGlassCurrencyPicker() {
        let app = launch("analytics")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Profile,")).firstMatch.tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Currency")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Select currency"].waitForExistence(timeout: 5))
        let currencyShot = XCTAttachment(screenshot: app.screenshot())
        currencyShot.name = "Currency picker original glass"
        currencyShot.lifetime = .keepAlways
        add(currencyShot)
        app.buttons["Close"].firstMatch.tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Categories,")).firstMatch.tap()
        let category = app.buttons["Groceries, expense category"]
        for _ in 0..<5 {
            if category.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(category.waitForExistence(timeout: 5))
        category.tap()
        XCTAssertTrue(app.textFields["Category name"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["Category name"].value as? String, "Groceries")
        let categoryShot = XCTAttachment(screenshot: app.screenshot())
        categoryShot.name = "Edit category from Settings grey"
        categoryShot.lifetime = .keepAlways
        add(categoryShot)
        app.buttons["Edit category icon"].tap()
        XCTAssertTrue(app.staticTexts["Choose Icon"].waitForExistence(timeout: 5))
        let iconShot = XCTAttachment(screenshot: app.screenshot())
        iconShot.name = "Icon picker native sheet material"
        iconShot.lifetime = .keepAlways
        add(iconShot)
        app.buttons["Close"].firstMatch.tap()
        XCTAssertTrue(app.textFields["Category name"].waitForExistence(timeout: 5))
        app.buttons["Close"].firstMatch.tap()
        XCTAssertTrue(category.waitForExistence(timeout: 5))
    }

    @MainActor func testCompactAccountAndCategoryCreationSheets() {
        let app = launch("analytics")
        func capture(_ name: String) {
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = name
            shot.lifetime = .keepAlways
            add(shot)
        }
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Profile,")).firstMatch.tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Accounts")).firstMatch.tap()
        app.buttons["Add Account"].firstMatch.tap()
        XCTAssertTrue(app.textFields["Account name"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Create"].isHittable)
        capture("New account compact material")
        app.textFields["Account name"].tap()
        app.textFields["Account name"].typeText("Test account")
        XCTAssertTrue(app.buttons["Create"].isHittable)
        capture("New account keyboard layout")
        app.buttons["Close"].firstMatch.tap()
        app.buttons["Discard Changes"].tap()
        XCTAssertTrue(app.buttons["Add Account"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Categories,")).firstMatch.tap()
        app.buttons["Add Options Menu"].firstMatch.tap()
        app.buttons["Create a Category"].tap()
        XCTAssertTrue(app.textFields["Category name"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Create"].isHittable)
        capture("New category compact material")
        app.textFields["Category name"].tap()
        app.textFields["Category name"].typeText("Test category")
        XCTAssertTrue(app.buttons["Create"].isHittable)
        capture("New category keyboard layout")
        app.buttons["Close"].firstMatch.tap()
        app.buttons["Discard Changes"].tap()
        XCTAssertTrue(app.buttons["Add Options Menu"].waitForExistence(timeout: 5))
    }

    @MainActor func testFolderCreationUsesCompactNativeMaterial() {
        let app = launch("analytics")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Profile,")).firstMatch.tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Categories,")).firstMatch.tap()
        app.buttons["Add Options Menu"].firstMatch.tap()
        app.buttons["Create a Folder"].tap()
        XCTAssertTrue(app.textFields["Folder name"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Create"].isHittable)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "New folder compact native material"
        shot.lifetime = .keepAlways
        add(shot)
        app.textFields["Folder name"].tap()
        app.textFields["Folder name"].typeText("Test folder")
        XCTAssertTrue(app.buttons["Create"].isHittable)
        app.buttons["Close"].firstMatch.tap()
        app.buttons["Discard Changes"].tap()
        XCTAssertTrue(app.buttons["Add Options Menu"].waitForExistence(timeout: 5))
    }

    @MainActor func testSubscriptionCreationUsesNativeMaterial() {
        let app = launch("subscription-detail")
        app.buttons["Subscriptions"].tap()
        app.buttons["Add Subscription"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["New Subscription"].waitForExistence(timeout: 5))
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "New subscription native material"
        shot.lifetime = .keepAlways
        add(shot)
        app.buttons["Edit subscription icon"].tap()
        XCTAssertTrue(app.staticTexts["Choose Icon"].waitForExistence(timeout: 5))
        app.buttons["Close"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["New Subscription"].waitForExistence(timeout: 5))
        app.buttons["Close"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Add Subscription"].waitForExistence(timeout: 5))
    }

    @MainActor func testMonthlyReceiptUsesNativeSheetBackground() {
        let app = launch("analytics")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Profile,")).firstMatch.tap()
        let receipt = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Monthly receipt")).firstMatch
        for _ in 0..<6 {
            if receipt.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(receipt.waitForExistence(timeout: 5))
        receipt.tap()
        XCTAssertTrue(app.staticTexts["Monthly Receipt"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["SPENDY EXPENSE REPORT"].exists)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Monthly receipt native background"
        shot.lifetime = .keepAlways
        add(shot)
        app.buttons["Close"].firstMatch.tap()
        XCTAssertTrue(receipt.waitForExistence(timeout: 5))
    }

    @MainActor func testSupportSheetUsesNativeMaterial() {
        let app = launch("analytics")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Profile,")).firstMatch.tap()
        let support = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Support Spendy")).firstMatch
        for _ in 0..<7 {
            if support.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(support.waitForExistence(timeout: 5))
        support.tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Buy me a coffee")).firstMatch.waitForExistence(timeout: 5))
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Support native sheet material"
        shot.lifetime = .keepAlways
        add(shot)
        app.buttons["Close"].firstMatch.tap()
        XCTAssertTrue(support.waitForExistence(timeout: 5))
    }

    @MainActor func testSubscriptionDetailUsesBottomSheetAndReturns() {
        let app = launch("subscription-detail")
        app.buttons["Subscriptions"].tap()
        let subscription = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Readiness Music")).allElementsBoundByIndex.first { $0.isHittable }
        guard let subscription else { XCTFail("Missing subscription"); return }
        subscription.tap()
        XCTAssertTrue(app.buttons["Edit Subscription"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Close"].isHittable)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Subscription detail bottom sheet"
        shot.lifetime = .keepAlways
        add(shot)
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["Subscriptions"].isHittable)
    }

    @MainActor func testCategoryPagesThroughAllFiveInsights() {
        let app = launch("insights")
        app.buttons["Analytics and statistics"].tap()
        let rows = app.buttons.matching(identifier: "breakdown-groceries")
        for _ in 0..<5 {
            if rows.allElementsBoundByIndex.contains(where: { $0.isHittable }) { break }
            app.swipeUp()
        }
        guard let row = rows.allElementsBoundByIndex.first(where: { $0.isHittable }) else { XCTFail("Missing category"); return }
        row.tap()
        XCTAssertTrue(app.buttons.matching(identifier: "next-insight").firstMatch.waitForExistence(timeout: 5))
        for _ in 0..<5 {
            if app.buttons.matching(identifier: "next-insight").allElementsBoundByIndex.contains(where: { $0.isHittable }) { break }
            app.swipeUp()
        }
        guard let next = app.buttons.matching(identifier: "next-insight").allElementsBoundByIndex.first(where: { $0.isHittable }) else { XCTFail("Missing category pager"); return }
        for index in 1...5 {
            XCTAssertEqual(next.value as? String, "Insight \(index) of 5")
            if index == 5 {
                let shot = XCTAttachment(screenshot: app.screenshot())
                shot.name = "Category fifth insight"
                shot.lifetime = .keepAlways
                add(shot)
            }
            next.tap()
        }
        XCTAssertEqual(next.value as? String, "Insight 1 of 5")
    }

}
