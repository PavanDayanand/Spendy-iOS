import XCTest

final class AmountEntryFlowUITests: XCTestCase {
    @MainActor private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "analytics"
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["More actions"].waitForExistence(timeout: 15))
        return app
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor func testInlineAccountBalanceUsesNativeKeyboard() {
        let app = launch()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Profile,")).firstMatch.tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Accounts")).firstMatch.tap()
        app.buttons["Add Account"].firstMatch.tap()
        let name = app.textFields["Account name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Native balance test")
        let balance = app.textFields["account-balance-input"]
        balance.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Account Balance"].exists)
        balance.typeText("1250.50")
        XCTAssertEqual(balance.value as? String, "1250.50")
        capture(app, "Inline account balance native keyboard")
        app.buttons["Create"].tap()
        XCTAssertTrue(app.staticTexts["Native balance test"].waitForExistence(timeout: 5))
    }

    @MainActor func testBudgetDecimalAndStartDaySurviveReopening() {
        let app = launch()
        app.buttons["More actions"].tap()
        app.buttons["Budget"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Set budget"].waitForExistence(timeout: 5))
        app.buttons["Set budget"].tap()
        XCTAssertTrue(app.staticTexts["Set Budget"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        for digit in ["5", "0", "0", ".", "5"] { app.buttons[digit].tap() }
        app.buttons["Weekly"].tap()
        app.buttons["Starts Mon"].tap()
        app.buttons["Wed"].tap()
        capture(app, "Budget shared transaction layout")
        app.buttons["Save"].tap()
        app.buttons["Budget Options"].tap()
        app.buttons["Edit Budget"].tap()
        XCTAssertTrue(app.staticTexts["500.50"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Starts Wed"].exists)
        capture(app, "Budget preserved decimal and start day")
    }
}
