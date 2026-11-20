import XCTest

final class MonthlyReceiptUITests: XCTestCase {
    @MainActor private func openReceipt(largeText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "charts"
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = "dark"
        if largeText {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 15))
        app.buttons["home-profile"].tap()
        let receipt = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Monthly receipt")).firstMatch
        for _ in 0..<6 {
            if receipt.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(receipt.isHittable)
        receipt.tap()
        XCTAssertTrue(app.navigationBars["Monthly Receipt"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor func testMonthChangeAndShare() {
        let app = openReceipt()
        XCTAssertTrue(app.staticTexts["SPENDY EXPENSE REPORT"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["monthly-receipt-share"].exists)
        capture(app, "Thermal printer and current month receipt")
        app.buttons["monthly-receipt-month-picker"].tap()
        let previous = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        app.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: previous.formatted(.dateTime.month(.wide)))
        app.navigationBars["Select Month"].buttons["Apply"].tap()
        let total = app.staticTexts["monthly-receipt-expense-total"]
        let changed = expectation(for: NSPredicate(format: "label CONTAINS %@", "1,500.00"), evaluatedWith: total)
        wait(for: [changed], timeout: 5)
        capture(app, "Previous month printed receipt")
        app.buttons["monthly-receipt-share"].tap()
        XCTAssertTrue(app.otherElements["ActivityListView"].waitForExistence(timeout: 5))
        capture(app, "Share the complete selected receipt")
    }

    @MainActor func testMonthChooserCancelsAndApplies() {
        let app = openReceipt()
        let month = app.buttons["monthly-receipt-month-picker"]
        let original = month.label
        month.tap()
        XCTAssertTrue(app.navigationBars["Select Month"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.pickerWheels.count, 2)
        capture(app, "Compact native month and year chooser")
        app.navigationBars["Select Month"].buttons["Cancel"].tap()
        XCTAssertEqual(month.label, original)
        month.tap()
        let previous = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        app.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: previous.formatted(.dateTime.month(.wide)))
        app.navigationBars["Select Month"].buttons["Apply"].tap()
        XCTAssertTrue(month.label.contains(previous.formatted(.dateTime.month(.wide))))
        XCTAssertTrue(app.staticTexts["monthly-receipt-expense-total"].label.contains("1,500.00"))
        capture(app, "Month picker applied to printed receipt")
    }

    @MainActor func testReceiptRemainsReachableAtLargeText() {
        let app = openReceipt(largeText: true)
        let scroll = app.scrollViews["monthly-receipt-scroll"]
        XCTAssertTrue(app.buttons["monthly-receipt-month-picker"].isHittable)
        scroll.swipeUp()
        XCTAssertFalse(app.buttons["monthly-receipt-reprint"].exists)
        XCTAssertTrue(app.buttons["monthly-receipt-share"].isHittable)
        capture(app, "Large text receipt with native controls")
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
