import XCTest

final class ReceiptActionUITests: XCTestCase {
    @MainActor func testMixedImageAndTextShowsActionAndExistingReview() {
        review("mixed")
    }

    @MainActor func testMixedPDFAndTextShowsActionAndExistingReview() {
        review("pdf")
    }

    @MainActor func testTextPaymentShowsActionAndExistingReview() {
        review("text")
    }

    @MainActor private func review(_ payload: String) {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "analytics"
        app.launchEnvironment["SPENDY_UI_TEST_ACTION_PAYLOAD"] = payload
        app.launchEnvironment["SPENDY_UI_TEST_RECEIPT_INTRO"] = "seen"
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        app.launchEnvironment["SPENDY_UI_TEST_RECEIPT_TEXT"] = "Google Pay\nPaid to Corner Cafe\n₹228\nCompleted\n17 Oct 2026\nUPI transaction ID 123456789012"
        app.launch()
        XCTAssertTrue(app.buttons["share-test-receipt"].waitForExistence(timeout: 10))
        app.buttons["share-test-receipt"].tap()
        let action = app.cells.matching(NSPredicate(format: "label CONTAINS %@", "Scan with Spendy")).firstMatch
        for _ in 0..<3 {
            if action.exists && action.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(action.waitForExistence(timeout: 8))
        let menuShot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        menuShot.name = "Scan with Spendy action - \(payload)"
        menuShot.lifetime = .keepAlways
        add(menuShot)
        action.tap()
        let note = app.buttons["receipt-review-note"]
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            note.exists || app.staticTexts["Receipt unavailable"].exists
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 35), .completed)
        guard note.exists else {
            print(app.debugDescription)
            XCTFail("The action should load the shared receipt")
            app.buttons["Close"].firstMatch.tap()
            return
        }
        XCTAssertEqual(note.value as? String, "Corner Cafe")
        XCTAssertTrue(app.staticTexts["receipt-review-title"].exists)
        XCTAssertTrue(app.buttons["add-scanned-receipt"].exists)
        XCTAssertFalse(app.buttons["add-scanned-receipt"].isEnabled, "Choose an account before adding")
        app.buttons["receipt-review-account"].tap()
        let cash = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Cash")).firstMatch
        XCTAssertTrue(cash.waitForExistence(timeout: 5))
        cash.tap()
        XCTAssertEqual(app.buttons["receipt-review-account"].value as? String, "Cash")
        XCTAssertTrue(app.buttons["add-scanned-receipt"].isEnabled)
        if payload == "mixed" {
            app.buttons["edit-scanned-receipt"].tap()
            let amount = app.textFields["receipt-amount-input"]
            XCTAssertTrue(amount.waitForExistence(timeout: 5))
            app.buttons["Cancel amount changes"].tap()
            XCTAssertTrue(app.buttons["receipt-review-note"].waitForExistence(timeout: 5))
        }
        let reviewShot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        reviewShot.name = "Shared original receipt review - \(payload)"
        reviewShot.lifetime = .keepAlways
        add(reviewShot)
        app.buttons["Close"].firstMatch.tap()
    }
}
