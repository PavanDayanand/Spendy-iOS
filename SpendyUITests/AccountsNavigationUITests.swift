import XCTest

final class AccountsNavigationUITests: XCTestCase {
    @MainActor func testAccountDirectoryVisibleWithoutScrollingLight() {
        verifyAccountDirectory(light: true, largeText: false)
    }

    @MainActor func testAccountDirectoryVisibleWithoutScrollingDark() {
        verifyAccountDirectory(light: false, largeText: false)
    }

    @MainActor func testAccountDirectoryFitsLargeText() {
        verifyAccountDirectory(light: true, largeText: true, fromSettings: true)
    }

    @MainActor func testSettingsAccountDirectoryVisibleWithoutScrolling() {
        verifyAccountDirectory(light: false, largeText: false, fromSettings: true)
    }

    @MainActor func testAccountsRespectInsightsSetting() {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "accounts-insights"
        app.launch()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 15))
        button("home-profile", in: app).tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Spendy Insights")).firstMatch.tap()
        let toggle = app.switches["Spendy Insights"].firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        if toggle.value as? String == "1" {
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }
        let disabled = expectation(for: NSPredicate(format: "value == %@", "0"), evaluatedWith: toggle)
        wait(for: [disabled], timeout: 5)
        capture(app, "Spendy Insights switched off")
        app.navigationBars["Spendy Insights"].buttons.element(boundBy: 0).tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Accounts")).firstMatch.tap()
        XCTAssertTrue(button("account-row-credit", in: app).waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Credit Card has a negative balance"].exists)
        XCTAssertFalse(button("next-insight", in: app).exists)
        capture(app, "Accounts with Insights disabled in Settings")
    }

    @MainActor private func verifyAccountDirectory(light: Bool, largeText: Bool, fromSettings: Bool = false) {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "accounts-insights"
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = light ? "light" : "dark"
        if largeText {
            app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 15))
        if fromSettings {
            button("home-profile", in: app).tap()
            app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Accounts")).firstMatch.tap()
        } else {
            button("All Accounts", in: app).tap()
            button("home-manage-accounts", in: app).tap()
            expectHeader("Accounts", in: app)
        }
        XCTAssertFalse(app.scrollViews["accounts-insight-pager"].exists)
        let first = button("account-row-cash", in: app)
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        if !largeText {
            XCTAssertTrue(first.isHittable, "The account list must start on the first screen")
        }
        XCTAssertFalse(button("accounts-open-insights", in: app).exists)
        XCTAssertFalse(app.navigationBars["Spendy insights"].exists)
        XCTAssertTrue(app.staticTexts["Credit Card has a negative balance"].waitForExistence(timeout: 5), "Insights are visible by default")
        capture(app, "Default account insights")
        button("next-insight", in: app).tap()
        XCTAssertTrue(app.staticTexts["Money in and out this month"].exists)
        button("next-insight", in: app).tap()
        XCTAssertTrue(app.staticTexts["Main Bank has your largest balance"].exists)
        capture(app, "Inline account balance insight")
        let last = button("account-row-credit", in: app)
        if largeText {
            for _ in 0..<6 {
                if last.isHittable { break }
                app.swipeUp()
            }
            XCTAssertTrue(last.isHittable, "All accounts remain reachable at accessibility sizes")
        } else {
            XCTAssertTrue(last.isHittable, "Three accounts should fit without scrolling")
            XCTAssertLessThanOrEqual(last.frame.maxY, app.frame.maxY)
            XCTAssertGreaterThanOrEqual(first.frame.height, 44)
            XCTAssertLessThanOrEqual(first.frame.height, 80)
        }
        capture(app, "Compact Accounts \(light ? "light" : "dark")\(largeText ? " large text" : "")\(fromSettings ? " from Settings" : "")")
        last.tap()
        if fromSettings {
            XCTAssertTrue(app.navigationBars["Credit Card"].waitForExistence(timeout: 5))
        } else {
            expectHeader("Credit Card", in: app)
        }
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
