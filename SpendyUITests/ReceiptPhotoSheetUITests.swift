import XCTest

final class ReceiptPhotoSheetUITests: XCTestCase {
    @MainActor private func launch(light: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "analytics"
        app.launchEnvironment["SPENDY_UI_TEST_RECEIPT_INTRO"] = "seen"
        app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = light ? "light" : "dark"
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        app.launchEnvironment["SPENDY_UI_TEST_RECEIPT_TEXT"] = "Paytm\nPaid Successfully\nRs. 750\nTo\nCorner Cafe\n12 Oct 2026\nUPI Ref No: 123456789012\nHDFC Bank XX2345"
        app.launch()
        XCTAssertTrue(app.buttons["home-receipt-scan"].waitForExistence(timeout: 10))
        return app
    }

    @MainActor func testCameraToPhotosKeepsCompactHeightAndCancels() {
        let app = launch()
        app.buttons["home-receipt-scan"].tap()
        app.buttons["Camera"].tap()
        if app.alerts.firstMatch.waitForExistence(timeout: 2) {
            let allow = app.alerts.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'allow'")).firstMatch
            if allow.exists { allow.tap() }
        }
        XCTAssertTrue(app.buttons["Camera options"].waitForExistence(timeout: 8))
        app.buttons["Camera options"].tap()
        app.buttons["Choose receipt photo"].tap()
        let cancel = app.buttons["Cancel"].firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 8))
        XCTAssertGreaterThan(cancel.frame.minY, app.frame.height * 0.2)
        XCTAssertLessThan(cancel.frame.minY, app.frame.height * 0.45)
        XCTAssertFalse(app.searchFields.firstMatch.exists)
        let panel = app.otherElements["receipt-photo-panel"].firstMatch
        XCTAssertTrue(panel.exists)
        XCTAssertGreaterThan(panel.frame.minX, 0)
        XCTAssertLessThan(panel.frame.maxX, app.frame.width)
        XCTAssertLessThan(panel.frame.maxY, app.frame.height)
        capture(app, "Receipt Photos at camera height")
        cancel.tap()
        XCTAssertTrue(app.buttons["home-receipt-scan"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Close camera"].exists)
        app.buttons["home-receipt-scan"].tap()
        XCTAssertTrue(app.buttons["Photos"].waitForExistence(timeout: 5))
    }

    @MainActor func testTransactionPhotosCancelsBackToForm() {
        let app = launch()
        app.buttons["Add Transaction"].tap()
        XCTAssertTrue(app.buttons["Add receipt"].waitForExistence(timeout: 5))
        app.buttons["Add receipt"].tap()
        app.buttons["Photos"].tap()
        let cancel = app.buttons["Cancel"].firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 8))
        XCTAssertGreaterThan(cancel.frame.minY, app.frame.height * 0.2)
        capture(app, "Transaction receipt Photos stays compact")
        cancel.tap()
        XCTAssertTrue(app.buttons["Add receipt"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["receipt-review-note"].exists)
    }

    @MainActor func testSelectedPhotoOpensReceiptReview() {
        let app = launch()
        app.buttons["home-receipt-scan"].tap()
        app.buttons["Photos"].tap()
        XCTAssertTrue(app.buttons["Cancel"].firstMatch.waitForExistence(timeout: 8))
        // The system picker may show its privacy introduction on first use.
        let continueButton = app.buttons["Continue"].firstMatch
        if continueButton.waitForExistence(timeout: 2) { continueButton.tap() }
        let privacyNotice = app.buttons["OK"].firstMatch
        if privacyNotice.waitForExistence(timeout: 3) { privacyNotice.tap() }
        let albums = app.buttons.matching(NSPredicate(format: "label == 'Albums' OR label == 'Collections'")).firstMatch
        XCTAssertTrue(albums.waitForExistence(timeout: 5))
        albums.tap()
        capture(app, "Native Albums browser in compact dark sheet")
        XCTAssertGreaterThan(app.buttons["Cancel"].firstMatch.frame.minY, app.frame.height * 0.2)
        let photos = app.buttons.matching(NSPredicate(format: "label == 'Photos'")).firstMatch
        XCTAssertTrue(photos.waitForExistence(timeout: 5))
        photos.tap()
        let photo = app.images.matching(NSPredicate(format: "label BEGINSWITH[c] 'Photo' ")).firstMatch
        if !photo.waitForExistence(timeout: 8) {
            let tree = XCTAttachment(string: app.debugDescription)
            tree.name = "System photo picker accessibility"
            tree.lifetime = .keepAlways
            add(tree)
        }
        XCTAssertTrue(photo.exists)
        let panel = app.otherElements["receipt-photo-panel"].firstMatch
        XCTAssertGreaterThan(panel.frame.minY, app.frame.height * 0.2)
        XCTAssertGreaterThan(app.buttons["Cancel"].firstMatch.frame.minY, app.frame.height * 0.2)
        XCTAssertLessThan(panel.frame.maxY, app.frame.height)
        capture(app, "Native Photos browser loaded in rounded panel")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.85))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.6)))
        capture(app, "Photo grid scrolled beneath native header")
        let visiblePhotos = app.images.matching(NSPredicate(format: "label BEGINSWITH[c] 'Photo' ")).allElementsBoundByIndex
        guard let visiblePhoto = visiblePhotos.first(where: {
            $0.isHittable && $0.frame.minY > app.buttons["Cancel"].firstMatch.frame.maxY + 12
                && $0.frame.maxY < panel.frame.maxY
        }) else {
            XCTFail("A complete photo row should be selectable below the floating header")
            return
        }
        visiblePhoto.tap()
        XCTAssertTrue(app.buttons["receipt-review-note"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.buttons["Cancel"].firstMatch.exists)
        capture(app, "Selected photo hands off to receipt review")
    }

    @MainActor func testPhotoSheetExpandsAndReturnsToCompactHeight() { verifyExpansion(light: false) }
    @MainActor func testLightPhotoSheetExpandsAndReturnsToCompactHeight() { verifyExpansion(light: true) }

    @MainActor private func verifyExpansion(light: Bool) {
        let app = launch(light: light)
        app.buttons["home-receipt-scan"].tap()
        app.buttons["Photos"].tap()
        let cancel = app.buttons["Cancel"].firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 8))
        let compactY = cancel.frame.midY
        XCTAssertGreaterThan(compactY, app.frame.height * 0.2)
        let privacy = app.buttons["OK"].firstMatch
        if privacy.waitForExistence(timeout: 2) { privacy.tap() }
        let panel = app.otherElements["receipt-photo-panel"].firstMatch
        let grabber = app.descendants(matching: .any).matching(NSPredicate(
            format: "label CONTAINS[c] 'grabber' OR identifier CONTAINS[c] 'grabber'"
        )).firstMatch
        XCTAssertFalse(grabber.exists, "The photo browser has no visible drag handle")
        let grabY = cancel.frame.midY
        let grabX = app.frame.width * 0.9
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: grabX, dy: grabY))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.10)))
        let expanded = expectation(for: NSPredicate { _, _ in
            panel.frame.minY < app.frame.height * 0.15 && panel.frame.height > app.frame.height * 0.88
        }, evaluatedWith: panel)
        wait(for: [expanded], timeout: 5)
        XCTAssertGreaterThanOrEqual(panel.frame.minX, 0)
        XCTAssertLessThanOrEqual(panel.frame.maxX, app.frame.width)
        XCTAssertLessThanOrEqual(panel.frame.maxY, app.frame.height)
        XCTAssertGreaterThan(panel.frame.width, app.frame.width * 0.98)
        XCTAssertFalse(grabber.exists)
        capture(app, "Receipt Photos system full height \(light ? "light" : "dark")")
        let expandedGrabY = cancel.frame.midY
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: grabX, dy: expandedGrabY))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: .zero)
                .withOffset(CGVector(dx: grabX, dy: grabY)))
        let compact = expectation(for: NSPredicate { _, _ in
            abs(cancel.frame.midY - compactY) < 30
        }, evaluatedWith: cancel)
        wait(for: [compact], timeout: 5)
        capture(app, "Receipt Photos compact system corners \(light ? "light" : "dark")")
        cancel.tap()
        XCTAssertTrue(app.buttons["home-receipt-scan"].waitForExistence(timeout: 5))
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = name
        image.lifetime = .keepAlways
        add(image)
    }
}
