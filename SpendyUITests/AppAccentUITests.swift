import XCTest

final class AppAccentUITests: XCTestCase {
    @MainActor private func openPicker(light: Bool = false, largeText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "charts"
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        if light { app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = "light" }
        if largeText { app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 15))
        app.buttons["home-profile"].tap()
        let accent = app.buttons["settings-app-accent"]
        XCTAssertTrue(accent.waitForExistence(timeout: 5))
        if !accent.isHittable { app.swipeUp() }
        accent.tap()
        XCTAssertTrue(app.buttons["accent-blue"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor func testAllPresetsDarkAndLiveButtons() {
        let app = openPicker()
        for name in ["blue", "green", "pink", "yellow", "white"] {
            app.buttons["accent-\(name)"].tap()
            XCTAssertEqual(app.buttons["accent-\(name)"].value as? String, "Selected")
            capture(app, "Dark accent \(name)")
        }
        app.buttons["accent-green"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["Add Transaction"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["Add Transaction"].value as? String, "Green")
        capture(app, "Green Add button on Home")
        app.buttons["Add Transaction"].tap()
        XCTAssertTrue(app.buttons["5"].waitForExistence(timeout: 5))
        app.buttons["5"].tap()
        XCTAssertTrue(app.buttons["Save"].isEnabled)
        XCTAssertEqual(app.buttons["Save"].value as? String, "Green")
        capture(app, "Green transaction Save")
    }

    @MainActor func testAllPresetsLight() {
        let app = openPicker(light: true)
        for name in ["blue", "green", "pink", "yellow", "white"] {
            app.buttons["accent-\(name)"].tap()
            XCTAssertEqual(app.buttons["accent-\(name)"].value as? String, "Selected")
            capture(app, "Light accent \(name)")
        }
    }

    @MainActor func testThemeChoicesUseFullWidthControl() {
        let app = openPicker(light: true)
        let system = app.buttons["System"]
        let dark = app.buttons["Dark"]
        XCTAssertTrue(system.exists)
        XCTAssertGreaterThan(dark.frame.maxX - system.frame.minX, app.frame.width * 0.65)
        for name in ["Dark", "Light", "System"] {
            app.buttons[name].tap()
            XCTAssertTrue(app.buttons[name].isSelected)
            capture(app, "Appearance theme \(name)")
        }
    }

    @MainActor func testSimpleAppearanceAndWhiteHomeAction() {
        let app = openPicker()
        app.buttons["accent-blue"].tap()
        capture(app, "Simple Appearance with blue selected")
        app.buttons["accent-white"].tap()
        capture(app, "Simple Appearance with white selected")
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["Add Transaction"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["Add Transaction"].value as? String, "White")
        capture(app, "White Home Add label")
    }

    @MainActor func testLargeTextPresetsStayAccessible() {
        let app = openPicker(light: true, largeText: true)
        let yellow = app.buttons["accent-yellow"]
        if !yellow.isHittable { app.swipeUp() }
        yellow.tap()
        XCTAssertEqual(yellow.value as? String, "Selected")
        capture(app, "Accent picker large text")
    }
}
