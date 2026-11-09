import XCTest
import UIKit

final class SpendyUITests: XCTestCase {
    @MainActor private func launch(_ mode: String = "standard", largeText: Bool = false, light: Bool = false, receiptText: String? = nil, rotatesInsights: Bool = false, tip: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_TIP"] = tip
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = mode
        app.launchEnvironment["SPENDY_UI_TEST_RECEIPT_INTRO"] = "seen"
        if !rotatesInsights { app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1" }
        if let receiptText { app.launchEnvironment["SPENDY_UI_TEST_RECEIPT_TEXT"] = receiptText }
        if light { app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = "light" }
        if largeText { app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        return app
    }

    @MainActor func testHomeAttentionDark() { verifyHomeAttention(light: false) }
    @MainActor func testHomeAttentionLight() { verifyHomeAttention(light: true) }

    @MainActor private func verifyHomeAttention(light: Bool) {
        let app = launch("home-attention", light: light, rotatesInsights: true)
        let priority = app.buttons["home-priority-insight"]
        XCTAssertTrue(priority.waitForExistence(timeout: 10))
        XCTAssertTrue(priority.label.contains("2 renewals today"))
        XCTAssertTrue(priority.isHittable)
        if !light {
            let changed = expectation(for: NSPredicate(format: "label CONTAINS[c] %@", "budget"), evaluatedWith: priority)
            changed.isInverted = true
            wait(for: [changed], timeout: 9)
        }
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Home renewals today priority \(light ? "light" : "dark")"
        shot.lifetime = .keepAlways
        add(shot)
        app.buttons["home-next-insight"].tap()
        XCTAssertTrue(priority.label.contains("budget"))
        app.buttons["home-next-insight"].tap()
        XCTAssertTrue(priority.label.contains("2 renewals today"))
        priority.tap()
        XCTAssertTrue(app.navigationBars["Spendy insights"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Needs your attention"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "2 renewals today")).firstMatch.exists)
    }

    @MainActor func testSingleHomeRenewalOpensFullInsights() {
        let app = launch("home-attention-single")
        let insight = app.buttons["home-priority-insight"]
        XCTAssertTrue(insight.waitForExistence(timeout: 10))
        XCTAssertTrue(insight.label.contains("Today Music renews today"))
        insight.tap()
        XCTAssertTrue(app.navigationBars["Spendy insights"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Needs your attention"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Today Music renews today")).firstMatch.exists)
        XCTAssertTrue(app.buttons["View spending details"].exists)
    }

    @MainActor func testHiddenAmountsKeepFullInsightsAccessible() {
        let app = launch("home-attention-single")
        XCTAssertTrue(app.buttons["More actions"].waitForExistence(timeout: 10))
        app.buttons["More actions"].tap()
        app.buttons["Hide Amounts"].tap()
        let entry = app.buttons["home-spending-insights"]
        XCTAssertTrue(entry.waitForExistence(timeout: 5))
        XCTAssertEqual(entry.label, "Spendy insights")
        entry.tap()
        XCTAssertTrue(app.navigationBars["Spendy insights"].waitForExistence(timeout: 5))
        let renewal = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Today Music renews today")).firstMatch
        XCTAssertTrue(renewal.exists)
        XCTAssertTrue(renewal.label.contains("••••"))
        XCTAssertFalse(renewal.label.contains("99"))
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Hidden amounts insight sheet"
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor func testDisabledInsightsClearlyOpenAnalytics() {
        let app = launch("insights-disabled")
        let entry = app.buttons["home-spending-insights"]
        XCTAssertTrue(entry.waitForExistence(timeout: 10))
        XCTAssertTrue(entry.label.contains("View analytics"))
        entry.tap()
        XCTAssertTrue(app.staticTexts["Analytics"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars["Spendy insights"].exists)
    }

    @MainActor func testHomeSummaryStaysStillAndRecentActivityExpands() {
        let app = launch("home-stability")
        let total = app.staticTexts["home-spending-total"]
        XCTAssertTrue(total.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Third recent expense"].isHittable)
        let initialY = total.frame.minY
        let canvas = app.scrollViews["home-spending-canvas"]
        canvas.swipeUp()
        XCTAssertEqual(total.frame.minY, initialY, accuracy: 2)
        canvas.swipeDown()
        XCTAssertEqual(total.frame.minY, initialY, accuracy: 2)
        XCTAssertTrue(app.buttons["home-priority-insight"].isHittable)
        XCTAssertTrue(app.buttons["Expand recent activity"].isHittable)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Stable Home and compact activity"
        shot.lifetime = .keepAlways
        add(shot)
        app.buttons["Expand recent activity"].tap()
        XCTAssertTrue(app.buttons["Collapse recent activity"].waitForExistence(timeout: 5))
        app.buttons["Collapse recent activity"].tap()
        XCTAssertTrue(app.buttons["Expand recent activity"].waitForExistence(timeout: 5))
        XCTAssertEqual(total.frame.minY, initialY, accuracy: 2)
    }

    @MainActor func testCreateCategoryFromTransactionPickerSelectsIt() {
        let app = launch()
        app.buttons["Add Transaction"].tap()
        XCTAssertTrue(app.buttons["Groceries"].waitForExistence(timeout: 5))
        app.buttons["Groceries"].tap()
        XCTAssertTrue(app.buttons["Create category"].waitForExistence(timeout: 5))
        app.buttons["Create category"].tap()
        XCTAssertTrue(app.textFields["Category name"].waitForExistence(timeout: 5))
        app.textFields["Category name"].tap()
        app.textFields["Category name"].typeText("Travel snacks")
        app.buttons["Create"].tap()
        XCTAssertTrue(app.buttons["Travel snacks"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["Category name"].exists)
        XCTAssertFalse(app.staticTexts["Select category"].exists)
    }

    @MainActor func testInteractiveIntroDark() { verifyInteractiveIntro(light: false) }
    @MainActor func testInteractiveIntroLight() { verifyInteractiveIntro(light: true) }

    @MainActor private func verifyInteractiveIntro(light: Bool) {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "standard"
        if light { app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = "light" }
        app.launchArguments = ["--onboarding"]
        app.launch()
        func capture(_ name: String) {
            Thread.sleep(forTimeInterval: 0.8) // Capture the settled state after the reveal/resize.
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = name + (light ? " light" : " dark")
            shot.lifetime = .keepAlways
            add(shot)
        }
        XCTAssertTrue(app.buttons["Get started"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Try logging a coffee"].exists)
        capture("Spendy welcome")
        app.buttons["Get started"].tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "intro-insight-brand").firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Continue"].isHittable)
        capture("Spendy insight reveal")
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Budget room"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Subscriptions"].exists)
        capture("Spendy budgets and subscriptions")
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Expense or income?"].waitForExistence(timeout: 5))
        capture("Spendy shortcut choices")
        XCTAssertTrue(app.staticTexts["11.11"].waitForExistence(timeout: 6))
        capture("Spendy shortcut amount prompt")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["Income"].waitForExistence(timeout: 5))
        app.buttons["Continue"].tap()
        let widget = app.buttons["intro-widget-resize"]
        XCTAssertTrue(widget.waitForExistence(timeout: 5))
        XCTAssertEqual(widget.value as? String, "Small")
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "intro-quick-launch-widget").firstMatch.exists)
        let smallWidth = widget.frame.width
        capture("Spendy small widget")
        widget.tap()
        XCTAssertEqual(widget.value as? String, "Medium")
        XCTAssertGreaterThan(widget.frame.width, smallWidth + 70)
        capture("Spendy medium widget")
        widget.tap()
        XCTAssertEqual(widget.value as? String, "Small")
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.buttons["Enable reminders"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Enable reminders"].isHittable)
        XCTAssertEqual(app.alerts.count, 0)
        capture("Spendy notification preview")
        app.buttons["Not now"].tap()
        XCTAssertTrue(app.buttons["Choose currency"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["Your name (optional)"].exists)
        XCTAssertFalse(app.staticTexts["Appearance"].exists)
        capture("Spendy branded currency setup")
        app.buttons["Choose currency"].tap()
        XCTAssertTrue(app.textFields["Search currency"].waitForExistence(timeout: 5))
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["Open Spendy"].isHittable)
    }

    @MainActor func testReceiptCameraGlassDark() { verifyReceiptCamera(light: false) }
    @MainActor func testReceiptCameraGlassLight() { verifyReceiptCamera(light: true) }

    @MainActor private func verifyReceiptCamera(light: Bool) {
        let app = launch("analytics", light: light)
        app.buttons["Add Transaction"].tap()
        XCTAssertTrue(app.buttons["Add receipt"].waitForExistence(timeout: 5))
        app.buttons["Add receipt"].tap()
        app.buttons["Camera"].tap()
        XCTAssertTrue(app.buttons["Close camera"].waitForExistence(timeout: 5))
        let options = app.buttons["Camera options"]
        XCTAssertTrue(options.isHittable)
        XCTAssertFalse(app.staticTexts["Receipt"].exists)
        let viewport = app.descendants(matching: .any).matching(identifier: "receipt-camera-viewport").firstMatch
        XCTAssertTrue(viewport.exists)
        let close = app.buttons["Close camera"]
        let shutter = app.buttons["Take receipt photo"]
        XCTAssertGreaterThan(close.frame.midY, viewport.frame.midY)
        XCTAssertLessThan(close.frame.maxY, viewport.frame.maxY)
        XCTAssertEqual(close.frame.midY, options.frame.midY, accuracy: 2)
        XCTAssertEqual(close.frame.midY, shutter.frame.midY, accuracy: 2)
        options.tap()
        XCTAssertTrue(app.buttons["Choose receipt photo"].waitForExistence(timeout: 5))
        viewport.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Receipt camera inset glass \(light ? "light" : "dark")"
        shot.lifetime = .keepAlways
        add(shot)
        app.buttons["Close camera"].tap()
        XCTAssertTrue(app.buttons["Add receipt"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["edit-scanned-receipt"].exists)
    }

    @MainActor private func openReceiptReview(_ app: XCUIApplication) {
        XCTAssertTrue(app.buttons["Add Transaction"].waitForExistence(timeout: 10))
        app.buttons["Add Transaction"].tap()
        XCTAssertTrue(app.buttons["Add receipt"].waitForExistence(timeout: 5))
        app.buttons["Add receipt"].tap()
        app.buttons["Paste image"].tap()
        XCTAssertTrue(app.buttons["edit-scanned-receipt"].waitForExistence(timeout: 15))
    }

    @MainActor func testIncomingReceiptReturnsToIncomeEditor() {
        let receipt = ["Paytm", "Money Received", "Rs. 3200", "Received from", "Anjali", "12 Oct 2026", "UPI Ref 123456789012"].joined(separator: "\n")
        let app = launch("analytics", receiptText: receipt)
        openReceiptReview(app)
        XCTAssertTrue(app.staticTexts["From"].exists)
        app.buttons["edit-scanned-receipt"].tap()
        XCTAssertTrue(app.buttons["Income"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Income"].isSelected)
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Amount,")).firstMatch.label.contains("3200"))
    }

    @MainActor func testPendingReceiptCannotBeAddedDirectly() {
        let receipt = ["PhonePe", "Payment Pending", "Rs. 750", "Paid to", "Corner Cafe", "12 Oct 2026", "UPI Ref 123456789012"].joined(separator: "\n")
        let app = launch("analytics", receiptText: receipt)
        openReceiptReview(app)
        XCTAssertFalse(app.buttons["add-scanned-receipt"].isEnabled)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Payment is pending")).firstMatch.exists)
        XCTAssertTrue(app.buttons["edit-scanned-receipt"].isEnabled)
    }

    @MainActor func testScannedReceiptAddsAndReturnsToHome() {
        let receipt = ["Paytm", "Paid Successfully", "Rs. 750", "To", "Corner Cafe", "12 Oct 2026", "HDFC Bank XX2345"].joined(separator: "\n")
        let app = launch("analytics", receiptText: receipt)
        openReceiptReview(app)
        XCTAssertTrue(app.buttons["add-scanned-receipt"].isEnabled)
        app.buttons["add-scanned-receipt"].tap()
        let home = app.buttons["Add Transaction"]
        let backHome = expectation(for: NSPredicate(format: "isHittable == true"), evaluatedWith: home)
        wait(for: [backHome], timeout: 5)
        XCTAssertFalse(app.buttons["edit-scanned-receipt"].exists)
        XCTAssertFalse(app.buttons["Add receipt"].exists)
    }

    @MainActor func testReceiptIntroductionOnlyOnFirstUse() {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "analytics"
        app.launchEnvironment["SPENDY_UI_TEST_RECEIPT_INTRO"] = "first-use"
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        app.launch()
        app.buttons["Add Transaction"].tap()
        app.buttons["Add receipt"].tap()
        XCTAssertTrue(app.staticTexts["Scan receipts"].waitForExistence(timeout: 5))
        XCTAssertLessThan(app.buttons["Close receipt introduction"].frame.midX, app.frame.midX)
        XCTAssertTrue(app.staticTexts["Apple Intelligence, when available"].exists)
        let reviewReminder = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "still in development")).firstMatch
        XCTAssertTrue(reviewReminder.exists)
        XCTAssertLessThan(reviewReminder.frame.maxY, app.buttons["receipt-introduction-continue"].frame.minY)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Receipt first-use introduction"
        shot.lifetime = .keepAlways
        add(shot)
        app.buttons["receipt-introduction-continue"].tap()
        XCTAssertTrue(app.buttons["Camera"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Choose receipt image"].exists)
        let sourceMenuShot = XCTAttachment(screenshot: app.screenshot())
        sourceMenuShot.name = "Receipt native OCR menu after introduction"
        sourceMenuShot.lifetime = .keepAlways
        add(sourceMenuShot)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)).tap()
        app.buttons["Add receipt"].tap()
        XCTAssertTrue(app.buttons["Photos"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Scan receipts"].exists)
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "SPENDY_UI_TEST_RECEIPT_INTRO")
        app.launch()
        app.buttons["Add Transaction"].tap()
        app.buttons["Add receipt"].tap()
        XCTAssertTrue(app.buttons["Photos"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Scan receipts"].exists)
    }

    @MainActor func testReceiptReviewDark() { verifyReceiptReview(light: false) }
    @MainActor func testReceiptReviewLight() { verifyReceiptReview(light: true) }

    @MainActor private func verifyReceiptReview(light: Bool) {
        let receipt = ["Paytm", "Paid Successfully", "Rs. 750", "To", "Corner Cafe", "12 Oct 2026", "UPI Ref No: 123456789012", "HDFC Bank XX2345"].joined(separator: "\n")
        let app = launch("analytics", light: light, receiptText: receipt)
        XCTAssertTrue(app.buttons["Add Transaction"].waitForExistence(timeout: 10))
        app.buttons["Add Transaction"].tap()
        XCTAssertTrue(app.buttons["Add receipt"].waitForExistence(timeout: 5))
        app.buttons["Add receipt"].tap()
        app.buttons["Paste image"].tap()
        if app.alerts.firstMatch.waitForExistence(timeout: 2) {
            let allow = app.alerts.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "allow paste")).firstMatch
            if allow.exists { allow.tap() }
        }
        guard app.buttons["edit-scanned-receipt"].waitForExistence(timeout: 15) else {
            XCTFail("Receipt review did not finish: \(app.debugDescription)")
            return
        }
        XCTAssertEqual(app.buttons["receipt-review-note"].value as? String, "Corner Cafe")
        XCTAssertTrue(app.buttons["receipt-review-note"].isHittable)
        XCTAssertFalse(app.staticTexts["Merchant"].exists)
        let title = app.staticTexts["receipt-review-title"]
        XCTAssertTrue(title.exists)
        XCTAssertEqual(title.frame.midX, app.frame.midX, accuracy: 2)
        XCTAssertLessThanOrEqual(title.frame.maxX, app.buttons["edit-scanned-receipt"].frame.minX)
        XCTAssertTrue(app.buttons["add-scanned-receipt"].isHittable)
        XCTAssertTrue(app.buttons["add-scanned-receipt"].isEnabled)
        XCTAssertGreaterThan(app.buttons["add-scanned-receipt"].frame.width, app.frame.width * 0.75)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Receipt review compact controls \(light ? "light" : "dark")"
        shot.lifetime = .keepAlways
        add(shot)
        app.buttons["edit-scanned-receipt"].tap()
        XCTAssertTrue(app.buttons["Add receipt"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["edit-scanned-receipt"].exists)
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Amount,")).firstMatch.label.contains("750"))
        let editorShot = XCTAttachment(screenshot: app.screenshot())
        editorShot.name = "Scanned amount returned to existing editor \(light ? "light" : "dark")"
        editorShot.lifetime = .keepAlways
        add(editorShot)
    }

    @MainActor func testMinimalWidgetsDark() { verifyMinimalWidgets(light: false) }
    @MainActor func testMinimalWidgetsLight() { verifyMinimalWidgets(light: true) }

    @MainActor private func verifyMinimalWidgets(light: Bool) {
        let app = launch("widgets", light: light)
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Profile,")).firstMatch.tap()
        let widgets = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "widgets")).firstMatch
        for _ in 0..<6 {
            if widgets.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(widgets.waitForExistence(timeout: 5))
        widgets.tap()
        XCTAssertTrue(app.staticTexts["Widgets that feel like Spendy"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.links["Add"].exists)
        XCTAssertTrue(app.links["Scan"].exists)
        XCTAssertTrue(app.links["Trends"].exists)
        func capture(_ section: String) {
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = "Minimal widgets \(light ? "light" : "dark") \(section)"
            shot.lifetime = .keepAlways
            add(shot)
        }
        capture("small")

        let familyPicker = app.segmentedControls["widget-family-picker"]
        XCTAssertTrue(familyPicker.waitForExistence(timeout: 5))
        familyPicker.buttons["Medium"].tap()
        capture("medium")

        familyPicker.buttons["Large"].tap()
        capture("large")
        familyPicker.buttons["XL"].tap()
        capture("extra large")
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
        app.buttons["analytics-stack-back"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
    }

    @MainActor func testSettingsCategoryEditorAndGlassCurrencyPicker() {
        let app = launch("analytics")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Profile,")).firstMatch.tap()
        app.buttons["Edit profile"].tap()
        XCTAssertTrue(app.buttons["profile-currency"].waitForExistence(timeout: 5))
        app.buttons["profile-currency"].tap()
        XCTAssertTrue(app.staticTexts["Select currency"].waitForExistence(timeout: 5))
        let currencyShot = XCTAttachment(screenshot: app.screenshot())
        currencyShot.name = "Currency picker original glass"
        currencyShot.lifetime = .keepAlways
        add(currencyShot)
        app.buttons["Close"].firstMatch.tap()
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

    @MainActor func testAnalyticsDiscoveryTip() {
        let app = launch("insights", tip: "analytics")
        XCTAssertTrue(app.staticTexts["Explore your spending"].waitForExistence(timeout: 10))
        captureTip(app, name: "Analytics discovery dark")
        // Dismiss the popover before using its anchor.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        app.buttons["Analytics and statistics"].tap()
        XCTAssertFalse(app.staticTexts["Explore your spending"].exists)
    }

    @MainActor func testHomeInsightDiscoveryTipLight() {
        let app = launch("home-attention", light: true, tip: "home-insight")
        XCTAssertTrue(app.staticTexts["Look closer"].waitForExistence(timeout: 10))
        captureTip(app, name: "Home insight discovery light")
    }

    @MainActor func testHomeTipsAdvanceWithoutWaiting() {
        let app = launch("home-attention", tip: "home-sequence")
        XCTAssertTrue(app.staticTexts["Explore your spending"].waitForExistence(timeout: 10))
        let close = app.buttons["Close"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        close.tap()
        XCTAssertTrue(app.staticTexts["Look closer"].waitForExistence(timeout: 10))
    }

    @MainActor func testSubscriptionDiscoveryTip() {
        let app = launch("subscription-detail", tip: "subscription")
        let subscriptions = app.buttons["Subscriptions"]
        XCTAssertTrue(subscriptions.waitForExistence(timeout: 10))
        // The glass dock can report no synthesized hit point; use its visible center.
        subscriptions.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.staticTexts["Manage your subscription"].waitForExistence(timeout: 10))
        captureTip(app, name: "Subscription management discovery")
    }

    @MainActor func testCategoryChartDiscoveryTip() {
        let app = launch("insights", tip: "category-chart")
        openTipTestCategory(app)
        XCTAssertTrue(app.staticTexts["Inspect your spending"].waitForExistence(timeout: 10))
        captureTip(app, name: "Category chart discovery")
    }

    @MainActor func testCategoryInsightDiscoveryTip() {
        let app = launch("insights", tip: "category-insight")
        openTipTestCategory(app)
        for _ in 0..<4 {
            if app.staticTexts["See another insight"].exists { break }
            app.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["See another insight"].waitForExistence(timeout: 10))
        captureTip(app, name: "Category insight discovery")
    }

    @MainActor func testCategoryTipsAdvanceWithoutWaiting() {
        let app = launch("insights", tip: "category-sequence")
        openTipTestCategory(app)
        XCTAssertTrue(app.staticTexts["Inspect your spending"].waitForExistence(timeout: 10))
        app.buttons["Close"].tap()
        for _ in 0..<4 {
            if app.staticTexts["See another insight"].exists { break }
            app.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["See another insight"].waitForExistence(timeout: 10))
    }

    @MainActor private func openTipTestCategory(_ app: XCUIApplication) {
        app.buttons["Analytics and statistics"].tap()
        let rows = app.buttons.matching(identifier: "breakdown-groceries")
        for _ in 0..<5 {
            if rows.allElementsBoundByIndex.contains(where: { $0.isHittable }) { break }
            app.swipeUp()
        }
        guard let row = rows.allElementsBoundByIndex.first(where: { $0.isHittable }) else {
            XCTFail("Missing category for tip verification")
            return
        }
        row.tap()
    }

    @MainActor private func captureTip(_ app: XCUIApplication, name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

}
