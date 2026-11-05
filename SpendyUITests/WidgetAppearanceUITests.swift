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

    @MainActor private func visibleWidget(_ springboard: XCUIApplication) -> XCUIElement {
        let widget = springboard.icons.matching(NSPredicate(format: "label == %@ AND value CONTAINS %@", "Spendy", "Widget")).firstMatch
        for _ in 0..<4 {
            if widget.exists && widget.frame.minX >= 0 && widget.frame.maxX <= springboard.frame.width && widget.frame.width > 100 { break }
            springboard.swipeLeft()
        }
        return widget
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
