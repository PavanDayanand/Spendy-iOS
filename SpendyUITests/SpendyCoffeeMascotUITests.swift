import XCTest

final class SpendyCoffeeMascotUITests: XCTestCase {
    @MainActor func testCoffeeBreakDark() { verifyCoffeeBreak(light: false) }
    @MainActor func testCoffeeBreakLight() { verifyCoffeeBreak(light: true) }

    @MainActor private func verifyCoffeeBreak(light: Bool) {
        let app = XCUIApplication()
        app.launchArguments = ["--onboarding", "--onboarding-step=0"]
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "standard"
        app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = light ? "light" : "dark"
        app.launch()

        let mascot = app.buttons["intro-coffee-mascot"]
        XCTAssertTrue(mascot.waitForExistence(timeout: 15))
        let loaded = expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: mascot)
        wait(for: [loaded], timeout: 15)
        XCTAssertEqual(mascot.label, "Make Spendy sip coffee")
        XCTAssertTrue(mascot.isHittable)
        capture(app, light: light, pose: "idle")
        mascot.tap()
        Thread.sleep(forTimeInterval: 0.7)
        capture(app, light: light, pose: "sip")
        Thread.sleep(forTimeInterval: 2)
        capture(app, light: light, pose: "returned")

        // The optional interaction must leave onboarding navigation usable.
        app.buttons["Get started"].tap()
        XCTAssertTrue(app.staticTexts["intro-insight-brand"].waitForExistence(timeout: 5))
        app.buttons["Back"].tap()
        XCTAssertTrue(mascot.waitForExistence(timeout: 5))
    }

    @MainActor private func capture(_ app: XCUIApplication, light: Bool, pose: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Coffee mascot \(light ? "light" : "dark") \(pose)"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
