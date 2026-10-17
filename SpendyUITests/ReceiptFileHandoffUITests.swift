import XCTest

/// Run with a synthetic receipt staged into the simulator's Photos library.
final class ReceiptFileHandoffUITests: XCTestCase {
    @MainActor func testPhotosShareOpensExistingReviewInMainApp() throws {
        try openSharedReceipt()
    }

    @MainActor func testPhotosShareLaunchesTerminatedAppIntoExistingReview() throws {
        try openSharedReceipt(cold: true)
    }

    @MainActor func testSharedReceiptSavesThroughExistingAddButton() throws {
        try openSharedReceipt(save: true)
    }

    @MainActor private func openSharedReceipt(cold: Bool = false, save: Bool = false) throws {
        guard ProcessInfo.processInfo.environment["SPENDY_SHARE_PHOTO_TEST"] == "1" else {
            throw XCTSkip("Stage the synthetic INR 135 receipt in simulator Photos and opt in with TEST_RUNNER_SPENDY_SHARE_PHOTO_TEST=1.")
        }
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "analytics"
        app.launchEnvironment["SPENDY_UI_TEST_RECEIPT_INTRO"] = "seen"
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        app.launch()
        if !cold && !save {
            app.buttons["home-receipt-scan"].tap()
            app.buttons["Photos"].tap()
            XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 8))
        }
        if cold { app.terminate() }
        let photos = XCUIApplication(bundleIdentifier: "com.apple.mobileslideshow")
        photos.launch()
        if photos.buttons["Continue"].waitForExistence(timeout: 3) { photos.buttons["Continue"].tap() }
        if photos.buttons["BackButton"].exists { photos.buttons["BackButton"].tap() }
        let images = photos.images.matching(identifier: "PXGGridLayout-Info")
        XCTAssertTrue(images.firstMatch.waitForExistence(timeout: 8))
        images.element(boundBy: images.count - 1).tap()
        XCTAssertTrue(photos.buttons["Share"].waitForExistence(timeout: 5))
        photos.buttons["Share"].tap()
        let shareShot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shareShot.name = "System share sheet"
        shareShot.lifetime = .keepAlways
        add(shareShot)
        let spendy = photos.cells["Spendy"]
        if !spendy.waitForExistence(timeout: 4) {
            let more = photos.cells["More"]
            if more.exists { more.tap() }
        }
        XCTAssertTrue(spendy.waitForExistence(timeout: 5))
        spendy.tap()
        XCTAssertTrue(app.buttons["receipt-review-note"].waitForExistence(timeout: 30))
        XCTAssertEqual(app.state, .runningForeground)
        XCTAssertEqual(app.buttons["receipt-review-note"].value as? String, "Corner Cafe")
        XCTAssertFalse(app.buttons["share-add-receipt"].exists)
        XCTAssertTrue(app.buttons["add-scanned-receipt"].isEnabled)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.lifetime = .keepAlways
        add(shot)
        if save {
            app.buttons["add-scanned-receipt"].tap()
            XCTAssertTrue(app.buttons["home-receipt-scan"].waitForExistence(timeout: 5))
            app.buttons["See all transactions"].tap()
            let search = app.textFields["Search transactions"]
            XCTAssertTrue(search.waitForExistence(timeout: 5))
            search.tap(); search.typeText("Corner Cafe")
            let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Corner Cafe, Expense")).firstMatch
            XCTAssertTrue(row.waitForExistence(timeout: 5))
            XCTAssertTrue(row.label.contains("135"))
        } else {
            app.buttons["Close"].tap()
            XCTAssertTrue(app.buttons["home-receipt-scan"].waitForExistence(timeout: 5))
        }
    }
}
