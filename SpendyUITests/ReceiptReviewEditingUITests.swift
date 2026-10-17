import XCTest

final class ReceiptReviewEditingUITests: XCTestCase {
    @MainActor private func openReview(light: Bool = false, hasDate: Bool = true, incoming: Bool = false, receiptCurrency: String = "Rs.") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "analytics"
        app.launchEnvironment["SPENDY_UI_TEST_RECEIPT_INTRO"] = "seen"
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = light ? "light" : "dark"
        var lines = ["Paytm", "Paid Successfully", "\(receiptCurrency) 750", "To", "Corner Cafe"]
        if incoming {
            lines = ["Paytm", "Payment received", "Rs. 750", "Received from", "Orion Zed"]
        }
        if hasDate { lines.append("12 Oct 2026") }
        lines += ["UPI Ref No: 123456789012", "HDFC Bank XX2345"]
        app.launchEnvironment["SPENDY_UI_TEST_RECEIPT_TEXT"] = lines.joined(separator: "\n")
        app.launch()
        XCTAssertTrue(app.buttons["Add Transaction"].waitForExistence(timeout: 10))
        app.buttons["Add Transaction"].tap()
        app.buttons["Add receipt"].tap()
        app.buttons["Paste image"].tap()
        XCTAssertTrue(app.buttons["receipt-review-note"].waitForExistence(timeout: 20))
        return app
    }

    @MainActor func testDifferentCurrencyNoticeKeepsSettingsCurrency() {
        let app = openReview(receiptCurrency: "€")
        let notice = app.alerts["Different currency detected"]
        XCTAssertTrue(notice.waitForExistence(timeout: 5))
        XCTAssertTrue(notice.staticTexts.matching(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "use €", "Spendy uses ₹")).firstMatch.exists)
        capture(app, "Different receipt currency native alert")
        notice.buttons["OK"].tap()
        XCTAssertTrue(app.buttons["receipt-review-note"].isHittable)
        XCTAssertFalse(notice.exists)
        app.buttons["receipt-review-note"].tap()
        app.buttons["Cancel note changes"].tap()
        XCTAssertFalse(notice.exists, "The notice appears once per scan")
    }

    @MainActor private func select(_ app: XCUIApplication, prefix: String) {
        let matches = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix))
        let target = matches.allElementsBoundByIndex.first { $0.isHittable } ?? matches.firstMatch
        XCTAssertTrue(target.waitForExistence(timeout: 5))
        target.tap()
    }

    @MainActor private func field(_ app: XCUIApplication, _ name: String) -> XCUIElement {
        let row = app.buttons["receipt-review-\(name)"]
        if !row.isHittable { app.swipeUp() }
        XCTAssertTrue(row.isHittable)
        return row
    }

    @MainActor private func changeNote(_ app: XCUIApplication, to note: String, save: Bool = true) {
        field(app, "note").tap()
        let editor = app.descendants(matching: .any).matching(identifier: "receipt-note-input").firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        let old = editor.value as? String ?? ""
        editor.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: old.count) + note)
        if save { app.buttons["receipt-note-done"].tap() }
        else { app.buttons["Cancel note changes"].tap() }
        XCTAssertTrue(app.buttons["receipt-review-note"].waitForExistence(timeout: 5))
    }

    @MainActor func testFourFieldsSaveDirectlyFromReview() {
        let app = openReview()
        changeNote(app, to: "Reviewed lunch receipt")
        XCTAssertEqual(app.buttons["receipt-review-note"].value as? String, "Reviewed lunch receipt")
        field(app, "category").tap()
        select(app, prefix: "Groceries")
        XCTAssertEqual(app.buttons["receipt-review-category"].value as? String, "Groceries")
        field(app, "account").tap()
        select(app, prefix: "Cash")
        XCTAssertEqual(app.buttons["receipt-review-account"].value as? String, "Cash")
        let originalDate = app.buttons["receipt-review-date"].value as? String
        field(app, "date").tap()
        select(app, prefix: "Today")
        XCTAssertNotEqual(app.buttons["receipt-review-date"].value as? String, originalDate)
        capture(app, "Receipt review with all four edited fields")
        XCTAssertTrue(app.buttons["add-scanned-receipt"].isEnabled)
        app.buttons["add-scanned-receipt"].tap()
        XCTAssertTrue(app.buttons["See all transactions"].waitForExistence(timeout: 8))
        app.buttons["See all transactions"].tap()
        let search = app.textFields["Search transactions"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Reviewed lunch receipt")
        let transaction = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@ AND label CONTAINS %@", "Reviewed lunch receipt,", ", Expense,")).firstMatch
        XCTAssertTrue(transaction.waitForExistence(timeout: 5))
        XCTAssertTrue(transaction.label.contains("Cash"))
        XCTAssertTrue(transaction.label.localizedCaseInsensitiveContains("today"))
        transaction.tap()
        XCTAssertTrue(app.staticTexts["Groceries"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Cash"].exists)
        XCTAssertTrue(app.staticTexts["Reviewed lunch receipt"].exists)
        capture(app, "Saved receipt keeps chosen category account and note")
    }

    @MainActor func testIncomeDetectionCanBeCorrectedToExpenseAndSaved() {
        let app = openReview(incoming: true)
        XCTAssertEqual(field(app, "category").value as? String, "Choose category")
        field(app, "category").tap()
        let types = app.segmentedControls["receipt-category-type"]
        XCTAssertTrue(types.waitForExistence(timeout: 5))
        XCTAssertTrue(types.buttons["Income"].isSelected)
        let groceries = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Groceries"))
        XCTAssertFalse(groceries.allElementsBoundByIndex.contains { $0.isHittable })
        select(app, prefix: "Salary / Paycheck")
        XCTAssertEqual(field(app, "category").value as? String, "Salary / Paycheck")
        field(app, "category").tap()
        types.buttons["Expense"].tap()
        select(app, prefix: "Groceries")
        XCTAssertEqual(field(app, "category").value as? String, "Groceries")
        field(app, "category").tap()
        XCTAssertTrue(types.buttons["Expense"].isSelected)
        types.buttons["Income"].tap()
        // Dismiss without choosing: the expense category must not survive the type change.
        app.buttons["Close category picker"].tap()
        XCTAssertEqual(field(app, "category").value as? String, "Choose category")
        XCTAssertFalse(app.buttons["add-scanned-receipt"].isEnabled)
        field(app, "category").tap()
        types.buttons["Expense"].tap()
        select(app, prefix: "Groceries")
        field(app, "account").tap()
        select(app, prefix: "Cash")
        XCTAssertTrue(app.buttons["add-scanned-receipt"].isEnabled)
        capture(app, "Receipt income detection corrected to expense")
        let note = app.buttons["receipt-review-note"].value as? String ?? ""
        XCTAssertFalse(note.isEmpty)
        app.buttons["add-scanned-receipt"].tap()
        let seeAll = app.buttons["See all transactions"]
        XCTAssertTrue(seeAll.waitForExistence(timeout: 8))
        let homeReady = expectation(for: NSPredicate(format: "hittable == true"), evaluatedWith: seeAll)
        wait(for: [homeReady], timeout: 8)
        seeAll.tap()
        let search = app.textFields["Search transactions"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText(note)
        let transaction = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@ AND label CONTAINS %@", "\(note),", ", Expense,")).firstMatch
        XCTAssertTrue(transaction.waitForExistence(timeout: 5))
        transaction.tap()
        XCTAssertTrue(app.staticTexts["Groceries"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Cash"].exists)
    }

    @MainActor func testNoteCancellationAndEditHandoffKeepDraft() {
        let app = openReview(light: true)
        changeNote(app, to: "Discarded change", save: false)
        XCTAssertEqual(app.buttons["receipt-review-note"].value as? String, "Corner Cafe")
        changeNote(app, to: "Receipt draft note")
        field(app, "account").tap()
        select(app, prefix: "Cash")
        app.buttons["edit-scanned-receipt"].tap()
        XCTAssertTrue(app.buttons["Add receipt"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Note, Receipt draft note"].exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Cash")).firstMatch.exists)
        capture(app, "Edited receipt draft retained in full editor")
    }

    @MainActor func testMissingDateCanBeChosenWithoutFullEditor() {
        let app = openReview(light: true, hasDate: false)
        XCTAssertEqual(app.buttons["receipt-review-date"].value as? String, "Choose date")
        XCTAssertFalse(app.buttons["add-scanned-receipt"].isEnabled)
        field(app, "date").tap()
        select(app, prefix: "Today")
        XCTAssertNotEqual(app.buttons["receipt-review-date"].value as? String, "Choose date")
        XCTAssertTrue(app.buttons["add-scanned-receipt"].isEnabled)
        capture(app, "Missing receipt date chosen in preview")
    }

    @MainActor func testCreateCategoryFromReceiptReturnsToDraft() {
        let app = openReview()
        field(app, "category").tap()
        app.buttons["Create category"].tap()
        let name = app.textFields["Category name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Receipt custom category")
        select(app, prefix: "Create")
        XCTAssertTrue(app.buttons["receipt-review-category"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["receipt-review-category"].value as? String, "Receipt custom category")
        XCTAssertEqual(app.buttons["receipt-review-note"].value as? String, "Corner Cafe")
        XCTAssertTrue(app.buttons["add-scanned-receipt"].isEnabled)
        capture(app, "New category selected in receipt draft")
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
