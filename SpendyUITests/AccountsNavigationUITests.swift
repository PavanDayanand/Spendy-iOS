import XCTest

final class AccountsNavigationUITests: XCTestCase {
    @MainActor func testAccountInsightsKeepTheirLayoutAcrossPages() {
        verifyInsightPages(largeText: false)
    }

    @MainActor func testAccountInsightsFitLargeText() {
        verifyInsightPages(largeText: true)
    }

    @MainActor private func verifyInsightPages(largeText: Bool) {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "accounts-insights"
        app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = "light"
        if largeText {
            app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 15))
        button("All Accounts", in: app).tap()
        button("home-manage-accounts", in: app).tap()
        expectHeader("Accounts", in: app)
        let pager = app.scrollViews["accounts-insight-pager"].firstMatch
        XCTAssertTrue(pager.waitForExistence(timeout: 5))
        let height = pager.frame.height
        XCTAssertGreaterThan(height, 40)
        capture(app, largeText ? "Account insight first page large text" : "Account insight first page")
        pager.swipeLeft()
        XCTAssertTrue(app.staticTexts["You're behind this month"].isHittable)
        XCTAssertEqual(pager.frame.height, height, accuracy: 2)
        capture(app, largeText ? "Account insight second page large text" : "Account insight second page")
        pager.swipeLeft()
        let third = button("accounts-insight-largest_bank", in: app)
        XCTAssertTrue(third.isHittable)
        XCTAssertEqual(pager.frame.height, height, accuracy: 2)
        capture(app, largeText ? "Account insight third page large text" : "Account insight third page")
        third.tap()
        expectHeader("Main Bank", in: app)
    }

    @MainActor func testManageAccountsHeaderAndReturnDark() {
        verifyManageAccounts(light: false)
    }

    @MainActor func testManageAccountsHeaderAndReturnLight() {
        verifyManageAccounts(light: true)
    }

    @MainActor private func verifyManageAccounts(light: Bool) {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "charts"
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = light ? "light" : "dark"
        app.launch()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 15))
        button("All Accounts", in: app).tap()
        button("home-manage-accounts", in: app).tap()
        expectHeader("Accounts", in: app)
        expectAction("accounts-add", in: app)
        let backFrame = button("analytics-stack-back", in: app).frame
        capture(app, "Manage Accounts shared header")

        // Repeat entry to catch stale parent actions after a pop.
        for attempt in 0..<2 {
            button("account-row-cash", in: app).tap()
            expectHeader("Cash", in: app)
            expectAction("analytics-stack-edit", in: app)
            XCTAssertFalse(button("accounts-add", in: app).exists)
            let total = app.staticTexts["entity-spending-total"].firstMatch
            XCTAssertTrue(total.exists)
            let originalTotal = total.label
            XCTAssertFalse(originalTotal.isEmpty)
            XCTAssertEqual(button("analytics-stack-back", in: app).frame.minY, backFrame.minY, accuracy: 1)
            if attempt == 0 {
                capture(app, "Account analytics keeps shared Back and Edit")
                button("analytics-stack-edit", in: app).tap()
                XCTAssertTrue(app.staticTexts["Edit Account"].waitForExistence(timeout: 5))
                XCTAssertTrue(app.staticTexts["Cash"].exists)
                XCTAssertFalse(app.textFields["Account name"].exists, "Cash has a read-only name")
                button("Close", in: app).tap()
                expectHeader("Cash", in: app)
                XCTAssertEqual(total.label, originalTotal)

                app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
                    .press(forDuration: 0.1,
                           thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.14, dy: 0.5)),
                           withVelocity: .slow, thenHoldForDuration: 0.6)
                expectHeader("Cash", in: app)
                expectAction("analytics-stack-edit", in: app)
            }
            button("analytics-stack-back", in: app).tap()
            expectHeader("Accounts", in: app)
            expectAction("accounts-add", in: app)
            XCTAssertFalse(button("analytics-stack-edit", in: app).exists)
        }

        let bank = button("account-row-bank", in: app)
        let bankName = bank.label.components(separatedBy: ",").first ?? ""
        XCTAssertFalse(bankName.isEmpty)
        bank.tap()
        expectHeader(bankName, in: app)
        button("analytics-stack-edit", in: app).tap()
        XCTAssertTrue(app.staticTexts["Edit Account"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["Account name"].firstMatch.value as? String, bankName)
        button("Close", in: app).tap()
        expectHeader(bankName, in: app)
        button("analytics-stack-back", in: app).tap()
        expectHeader("Accounts", in: app)

        button("accounts-add", in: app).tap()
        XCTAssertTrue(app.staticTexts["New Account"].waitForExistence(timeout: 5))
        button("Close", in: app).tap()
        expectHeader("Accounts", in: app)
        capture(app, "Accounts Add action restored")
        button("analytics-stack-back", in: app).tap()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Analytics and statistics"].isHittable)
    }

    @MainActor private func expectHeader(_ title: String, in app: XCUIApplication) {
        let label = app.staticTexts.matching(identifier: "analytics-stack-title").firstMatch
        let match = expectation(for: NSPredicate(format: "label == %@", title), evaluatedWith: label)
        wait(for: [match], timeout: 5)
        let backs = app.buttons.matching(identifier: "analytics-stack-back").allElementsBoundByIndex.filter { $0.isHittable }
        XCTAssertEqual(backs.count, 1)
        if let back = backs.first {
            let visibleBacks = app.buttons.matching(NSPredicate(format: "label == %@", "Back"))
                .allElementsBoundByIndex.filter { $0.isHittable && abs($0.frame.midY - back.frame.midY) < 20 }
            XCTAssertEqual(visibleBacks.count, 1)
        }
    }

    @MainActor private func expectAction(_ id: String, in app: XCUIApplication) {
        let ready = expectation(for: NSPredicate { _, _ in
            MainActor.assumeIsolated { self.button(id, in: app).isHittable }
        }, evaluatedWith: app)
        wait(for: [ready], timeout: 5)
    }

    @MainActor private func button(_ id: String, in app: XCUIApplication) -> XCUIElement {
        let matches = app.buttons.matching(identifier: id)
        return matches.allElementsBoundByIndex.first { $0.isHittable } ?? matches.firstMatch
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
