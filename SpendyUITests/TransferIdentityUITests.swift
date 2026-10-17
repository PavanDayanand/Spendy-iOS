import XCTest

final class TransferIdentityUITests: XCTestCase {
    @MainActor func testLegacyTransferShowsItsOwnIdentity() {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "transfer-regression"
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        app.launch()
        let route = app.staticTexts["Main Bank → Savings Bank"]
        XCTAssertTrue(route.waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Bank to bank"].exists)
        XCTAssertFalse(app.staticTexts["Groceries"].exists)
        capture(app, "Compact transfer row on Home")
        route.tap()
        XCTAssertTrue(app.staticTexts["Transfer"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Main Bank"].exists)
        XCTAssertTrue(app.staticTexts["Savings Bank"].exists)
        XCTAssertFalse(app.staticTexts["Groceries"].exists)
        capture(app, "Transfer detail uses transfer identity")
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
