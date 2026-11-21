import XCTest

final class MonochromeAppearanceUITests: XCTestCase {
    @MainActor func testAppearanceMenuChangesModeWithoutLeavingSettings() {
        for light in [false, true] {
            let app = XCUIApplication()
            app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "charts"
            app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
            if light { app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = "light" }
            app.launch()
            XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 15))
            app.buttons["home-profile"].tap()
            let appearance = app.buttons["settings-appearance"]
            XCTAssertTrue(appearance.waitForExistence(timeout: 5))
            if !appearance.isHittable { app.swipeUp() }
            appearance.tap()
            for title in ["System", "Light", "Dark"] {
                XCTAssertTrue(app.buttons[title].waitForExistence(timeout: 5), title)
            }
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Appearance menu \(light ? "light" : "dark")"
            attachment.lifetime = .keepAlways
            add(attachment)
            let target = light ? "Dark" : "Light"
            app.buttons[target].tap()
            XCTAssertTrue(app.navigationBars["Settings"].exists)
            XCTAssertEqual(appearance.value as? String, target)
            XCTAssertFalse(app.navigationBars["Appearance"].exists)
            appearance.tap()
            app.buttons["System"].tap()
            XCTAssertEqual(appearance.value as? String, "System")
            XCTAssertFalse(app.staticTexts["App accent"].exists)
            XCTAssertFalse(app.staticTexts["Home background"].exists)
            XCTAssertFalse(app.staticTexts["App icons"].exists)
            app.terminate()
        }
    }
}
