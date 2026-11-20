import XCTest

final class NativeControlsUITests: XCTestCase {
    @MainActor func testBrowserAddAndCalendarReturnWithoutChangingDraft() {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "charts"
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["See all transactions"].waitForExistence(timeout: 15))
        app.buttons["See all transactions"].tap()
        let add = app.buttons["transactions-add"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.tap()
        let close = app.buttons["Close"].firstMatch
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(close.frame.width, 44)
        XCTAssertGreaterThanOrEqual(close.frame.height, 44)
        app.buttons["Today"].tap()
        let calendar = app.navigationBars["Select Date"]
        XCTAssertTrue(calendar.waitForExistence(timeout: 5))
        calendar.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["Today"].waitForExistence(timeout: 5))
        close.tap()
        XCTAssertFalse(app.alerts["Discard Changes?"].exists)
        XCTAssertTrue(app.navigationBars["All Transactions"].waitForExistence(timeout: 5))
        XCTAssertTrue(add.isHittable)
        XCTAssertTrue(app.searchFields["Search transactions"].exists)
    }
}
