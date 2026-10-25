import XCTest

final class NavigationContinuityUITests: XCTestCase {
    @MainActor func testBreakdownCategoryTransactionEditReturnsThroughOneHeader() {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "charts"
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 15))
        app.buttons["Analytics and statistics"].tap()
        expectHeader("Analytics", in: app)
        revealButton("expand-spending-breakdown", in: app).tap()
        expectHeader("Spending by Category", in: app)
        let backFrame = button("analytics-stack-back", in: app).frame
        capture(app, "Breakdown uses persistent header")

        revealButton("breakdown-groceries", in: app).tap()
        expectHeader("Groceries", in: app)
        XCTAssertTrue(app.staticTexts["entity-spending-total"].firstMatch.label.contains("600"))
        XCTAssertEqual(button("analytics-stack-back", in: app).frame.minY, backFrame.minY, accuracy: 1)

        revealButton("Recent Activity", in: app).tap()
        let transaction = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Chart groceries")).firstMatch
        for _ in 0..<4 {
            if transaction.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(transaction.isHittable)
        transaction.tap()
        XCTAssertTrue(button("Edit Transaction", in: app).waitForExistence(timeout: 5))
        button("Edit Transaction", in: app).tap()
        XCTAssertTrue(button("Close", in: app).waitForExistence(timeout: 5))
        XCTAssertFalse(button("Edit Transaction", in: app).exists, "Detail must dismiss before editor opens")
        capture(app, "Transaction editor replaces detail")
        button("Close", in: app).tap()
        expectHeader("Groceries", in: app)
        XCTAssertFalse(button("Edit Transaction", in: app).exists)

        // Cancelling a back gesture must leave the current route's controls intact.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
            .press(forDuration: 0.1,
                   thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.14, dy: 0.5)),
                   withVelocity: .slow, thenHoldForDuration: 0.6)
        expectHeader("Groceries", in: app)
        button("analytics-stack-back", in: app).tap()
        expectHeader("Spending by Category", in: app)
        XCTAssertTrue(button("breakdown-menu", in: app).isHittable)
        XCTAssertTrue(app.staticTexts["breakdown-total"].label.contains("1,200"))
        capture(app, "Breakdown restored after transaction editing")
        button("analytics-stack-back", in: app).tap()
        expectHeader("Analytics", in: app)
        button("analytics-stack-back", in: app).tap()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["home-spending-total"].firstMatch.label.contains("1,200"), true)
    }

    @MainActor private func expectHeader(_ title: String, in app: XCUIApplication) {
        let label = app.staticTexts.matching(identifier: "analytics-stack-title").firstMatch
        let correctTitle = expectation(for: NSPredicate(format: "label == %@", title), evaluatedWith: label)
        wait(for: [correctTitle], timeout: 5)
        let backs = app.buttons.matching(identifier: "analytics-stack-back").allElementsBoundByIndex.filter { $0.isHittable }
        XCTAssertEqual(backs.count, 1)
        if let back = backs.first {
            let visibleHeaderBacks = app.buttons.matching(NSPredicate(format: "label == %@", "Back"))
                .allElementsBoundByIndex.filter { $0.isHittable && abs($0.frame.midY - back.frame.midY) < 20 }
            XCTAssertEqual(visibleHeaderBacks.count, 1)
        }
    }

    @MainActor private func button(_ id: String, in app: XCUIApplication) -> XCUIElement {
        let matches = app.buttons.matching(identifier: id)
        return matches.allElementsBoundByIndex.first { $0.isHittable } ?? matches.firstMatch
    }

    @MainActor private func revealButton(_ id: String, in app: XCUIApplication) -> XCUIElement {
        for _ in 0..<4 {
            let target = button(id, in: app)
            if target.isHittable { return target }
            app.swipeUp()
        }
        let target = button(id, in: app)
        XCTAssertTrue(target.isHittable, "Expected reachable button: \(id)")
        return target
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
