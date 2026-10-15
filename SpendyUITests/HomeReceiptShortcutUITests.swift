import XCTest

final class HomeReceiptShortcutUITests: XCTestCase {
    @MainActor private func launch(light: Bool = false, firstUse: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "analytics"
        app.launchEnvironment["SPENDY_UI_TEST_RECEIPT_INTRO"] = firstUse ? "first-use" : "seen"
        app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = light ? "light" : "dark"
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        app.launchEnvironment["SPENDY_UI_TEST_RECEIPT_TEXT"] = ["Paytm", "Paid Successfully", "Rs. 750", "To", "Corner Cafe", "12 Oct 2026", "UPI Ref No: 123456789012", "HDFC Bank XX2345"].joined(separator: "\n")
        app.launch()
        XCTAssertTrue(app.buttons["home-receipt-scan"].waitForExistence(timeout: 10))
        return app
    }

    @MainActor private func openPreview(_ app: XCUIApplication) {
        app.buttons["home-receipt-scan"].tap()
        app.buttons["Paste image"].tap()
        XCTAssertTrue(app.buttons["receipt-review-note"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.buttons["Add receipt"].exists, "The transaction form should not be underneath this preview")
        XCTAssertEqual(app.buttons["receipt-review-note"].value as? String, "Corner Cafe")
    }

    @MainActor func testDirectPreviewSavesChosenAccountFromHome() {
        let app = launch()
        capture(app, "Home receipt shortcut beside Add")
        openPreview(app)
        app.buttons["receipt-review-account"].tap()
        let cash = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Cash")).allElementsBoundByIndex.first { $0.isHittable }
        XCTAssertNotNil(cash)
        cash?.tap()
        XCTAssertEqual(app.buttons["receipt-review-account"].value as? String, "Cash")
        capture(app, "Receipt preview opened directly from Home")
        app.buttons["add-scanned-receipt"].tap()
        XCTAssertTrue(app.buttons["home-receipt-scan"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Add receipt"].exists)
        app.buttons["See all transactions"].tap()
        let search = app.textFields["Search transactions"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Corner Cafe")
        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Corner Cafe, Expense")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("Cash"))
        XCTAssertTrue(row.label.contains("750"))
    }

    @MainActor func testEditHandoffKeepsScanAndNormalAddStartsEmpty() {
        let app = launch(light: true)
        openPreview(app)
        app.buttons["edit-scanned-receipt"].tap()
        XCTAssertTrue(app.buttons["Add receipt"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Note, Corner Cafe"].exists)
        let amount = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Amount,")).firstMatch
        XCTAssertTrue(amount.label.contains("750"))
        app.buttons["Close"].firstMatch.tap()
        if app.alerts.firstMatch.waitForExistence(timeout: 2) {
            app.alerts.buttons["Discard Changes"].tap()
        }
        XCTAssertTrue(app.buttons["home-receipt-scan"].waitForExistence(timeout: 5))
        app.buttons["Add Transaction"].tap()
        XCTAssertTrue(app.buttons["Add receipt"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Note, Corner Cafe"].exists)
        XCTAssertFalse(amount.label.contains("750"))
        capture(app, "Normal Add remains independent of receipt shortcut")
    }

    @MainActor func testFirstUseSourcesAndCancellationReturnToHome() {
        let app = launch(firstUse: true)
        app.buttons["home-receipt-scan"].tap()
        XCTAssertTrue(app.staticTexts["Scan receipts"].waitForExistence(timeout: 5))
        app.buttons["receipt-introduction-continue"].tap()
        XCTAssertTrue(app.buttons["Photos"].waitForExistence(timeout: 5))
        app.buttons["Photos"].tap()
        let cancel = app.buttons["Cancel"].firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 8))
        cancel.tap()
        XCTAssertTrue(app.buttons["home-receipt-scan"].waitForExistence(timeout: 5))
        app.buttons["home-receipt-scan"].tap()
        XCTAssertTrue(app.buttons["Camera"].waitForExistence(timeout: 5))
        app.buttons["Camera"].tap()
        if app.alerts.firstMatch.waitForExistence(timeout: 2) {
            let allow = app.alerts.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "allow")).firstMatch
            if allow.exists { allow.tap() }
        }
        XCTAssertTrue(app.buttons["Close camera"].waitForExistence(timeout: 8))
        app.buttons["Close camera"].tap()
        XCTAssertTrue(app.buttons["home-receipt-scan"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Add receipt"].exists)
    }

    @MainActor func testDockPlacementExpandedAndHomeOnly() {
        let app = launch(light: true)
        let receipt = app.buttons["home-receipt-scan"]
        let add = app.buttons["Add Transaction"]
        XCTAssertEqual(receipt.frame.width, 44, accuracy: 0.5)
        XCTAssertLessThan(receipt.frame.maxX, add.frame.minX)
        XCTAssertLessThanOrEqual(add.frame.maxX, app.frame.maxX)
        app.buttons["Expand recent activity"].tap()
        XCTAssertTrue(app.buttons["Collapse recent activity"].waitForExistence(timeout: 5))
        XCTAssertTrue(receipt.isHittable)
        XCTAssertTrue(add.isHittable)
        XCTAssertLessThan(receipt.frame.maxX, add.frame.minX)
        capture(app, "Expanded Home drawer keeps receipt and Add separate")
        app.buttons["Subscriptions"].tap()
        XCTAssertFalse(receipt.exists)
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
