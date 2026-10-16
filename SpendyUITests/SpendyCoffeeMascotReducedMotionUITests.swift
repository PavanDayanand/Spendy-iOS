import XCTest
import UIKit

/// Run with Reduce Motion enabled on the simulator.
final class SpendyCoffeeMascotReducedMotionUITests: XCTestCase {
    @MainActor func testStillMascotKeepsOnboardingUsable() throws {
        guard UIAccessibility.isReduceMotionEnabled else {
            throw XCTSkip("Enable Reduce Motion on the simulator to run this check.")
        }
        let app = XCUIApplication()
        app.launchArguments = ["--onboarding", "--onboarding-step=0"]
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "standard"
        app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = "light"
        app.launch()
        let mascot = app.images["intro-coffee-mascot"]
        XCTAssertTrue(mascot.waitForExistence(timeout: 10))
        XCTAssertEqual(mascot.label, "Spendy’s coffee character")
        XCTAssertFalse(app.buttons["intro-coffee-mascot"].exists)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Coffee mascot Reduce Motion"
        shot.lifetime = .keepAlways
        add(shot)
        app.buttons["Get started"].tap()
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5))
    }
}
