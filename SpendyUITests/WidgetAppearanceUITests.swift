import XCTest

// Opt in after installing a Spendy widget on the Simulator Home Screen.
// This capture restores the default icon appearance and reloads the real ledger.
final class WidgetAppearanceUITests: XCTestCase {
    override func setUpWithError() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["SPENDY_WIDGET_APPEARANCE_CHECK"] == "1" || ProcessInfo.processInfo.environment["TEST_RUNNER_SPENDY_WIDGET_APPEARANCE_CHECK"] == "1")
    }

    @MainActor func testHomeScreenWidgetAppearance() {
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        openAppearanceControls(springboard)
        let clear = springboard.buttons["Clear"]
        XCTAssertTrue(clear.waitForExistence(timeout: 5))
        clear.tap()
        XCUIDevice.shared.press(.home)
        let widget = visibleWidget(springboard)
        XCTAssertTrue(widget.exists)
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "Clear Home Screen widgets"
        shot.lifetime = .keepAlways
        add(shot)
        print("WIDGET_HOME_TREE_START\n" + springboard.debugDescription + "\nWIDGET_HOME_TREE_END")
        openAppearanceControls(springboard)
        let original = springboard.buttons["Default"]
        XCTAssertTrue(original.waitForExistence(timeout: 5))
        original.tap()
        XCUIDevice.shared.press(.home)
        XCUIApplication().launch()
    }

    @MainActor func testBudgetAndSubscriptionAppearances() {
        XCUIDevice.shared.press(.home)
        XCUIDevice.shared.press(.home)
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "widgets"
        app.launchEnvironment["SPENDY_UI_TEST_RECEIPT_INTRO"] = "seen"
        app.launch()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Profile,")).firstMatch.tap()
        let widgets = app.buttons["settings-widgets"]
        for _ in 0..<6 {
            if widgets.isHittable { break }
            app.swipeUp()
        }
        widgets.tap()
        XCTAssertTrue(app.staticTexts["Widgets that feel like Spendy"].waitForExistence(timeout: 5))
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCTAssertTrue(visibleWidget(springboard).exists)
        for title in ["Budget Room", "Subscriptions"] {
            if springboard.staticTexts[title == "Budget Room" ? "Budget" : title].exists { continue }
            visibleWidget(springboard).press(forDuration: 1.2)
            springboard.buttons["Edit Home Screen"].tap()
            springboard.buttons["Edit"].tap()
            springboard.buttons["Add Widget"].tap()
            let search = springboard.searchFields.firstMatch
            XCTAssertTrue(search.waitForExistence(timeout: 5))
            search.tap()
            search.typeText("Spendy")
            let result = springboard.cells["Spendy"].firstMatch
            XCTAssertTrue(result.waitForExistence(timeout: 5))
            result.tap()
            for _ in 0..<12 {
                if springboard.staticTexts[title].exists { break }
                springboard.swipeLeft()
            }
            XCTAssertTrue(springboard.staticTexts[title].exists)
            springboard.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Add Widget")).firstMatch.tap()
            XCUIDevice.shared.press(.home)
        }
        XCTAssertTrue(springboard.staticTexts["₹635"].waitForExistence(timeout: 20))
        for mode in ["Default", "Dark", "Clear"] {
            openAppearanceControls(springboard)
            springboard.buttons[mode].tap()
            XCUIDevice.shared.press(.home)
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "Budget and subscriptions \(mode)"
            shot.lifetime = .keepAlways
            add(shot)
        }
        openAppearanceControls(springboard)
        springboard.buttons["Default"].tap()
        XCUIDevice.shared.press(.home)
        app.launch()
    }

    @MainActor private func visibleWidget(_ springboard: XCUIApplication) -> XCUIElement {
        let query = springboard.icons.matching(NSPredicate(format: "label == %@ AND value CONTAINS %@", "Spendy", "Widget"))
        func current() -> XCUIElement? {
            guard query.firstMatch.exists else { return nil }
            return query.allElementsBoundByIndex.first {
                $0.exists && $0.frame.minX >= 0 && $0.frame.maxX <= springboard.frame.width && $0.frame.width > 100
            }
        }
        if let widget = current() { return widget }
        XCUIDevice.shared.press(.home)
        XCUIDevice.shared.press(.home)
        for _ in 0..<5 {
            if let widget = current() { return widget }
            springboard.swipeLeft()
        }
        return query.firstMatch
    }

    @MainActor private func openAppearanceControls(_ springboard: XCUIApplication) {
        let widget = visibleWidget(springboard)
        XCTAssertTrue(widget.exists)
        widget.press(forDuration: 1.2)
        let editHome = springboard.buttons["Edit Home Screen"]
        if editHome.waitForExistence(timeout: 4) { editHome.tap() }
        let edit = springboard.buttons["Edit"]
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        edit.tap()
        let customize = springboard.buttons["Customize"]
        XCTAssertTrue(customize.waitForExistence(timeout: 5))
        customize.tap()
    }
}
