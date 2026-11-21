import XCTest

final class PrivacyPolicyUITests: XCTestCase {
    @MainActor private func launch(light: Bool, largeText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "analytics"
        app.launchEnvironment["SPENDY_DISABLE_INSIGHT_ROTATION"] = "1"
        app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = light ? "light" : "dark"
        if largeText {
            app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 10))
        app.buttons["home-profile"].tap()
        let about = app.buttons["settings-help-about"]
        for _ in 0..<8 {
            if about.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(about.isHittable)
        about.tap()
        let row = app.buttons["settings-privacy-policy"]
        for _ in 0..<8 {
            if row.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(row.isHittable)
        let terms = app.descendants(matching: .any).matching(identifier: "settings-terms-of-use").firstMatch
        for _ in 0..<3 {
            if terms.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(terms.isHittable)
        row.tap()
        XCTAssertTrue(app.staticTexts["Information you keep in Spendy"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Privacy policy unavailable"].exists)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "privacy-policy-online").firstMatch.exists)
        return app
    }

    @MainActor func testPrivacyDocumentAndReturnDark() {
        let app = launch(light: false)
        let receiptHeading = app.staticTexts["Receipt images and scanning"]
        for _ in 0..<6 {
            if receiptHeading.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(receiptHeading.isHittable)
        capture(app, "Native privacy policy dark")
        app.navigationBars["Privacy Policy"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["settings-privacy-policy"].waitForExistence(timeout: 5))
    }

    @MainActor func testPrivacyDocumentAtLargestTextLight() {
        let app = launch(light: true, largeText: true)
        XCTAssertTrue(app.navigationBars["Privacy Policy"].exists)
        capture(app, "Native privacy policy largest text light")
        app.navigationBars["Privacy Policy"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["settings-privacy-policy"].waitForExistence(timeout: 5))
    }

    @MainActor func testHelpIncludesSupportWithoutExternalTip() {
        let app = launch(light: true)
        app.navigationBars["Privacy Policy"].buttons.element(boundBy: 0).tap()
        let support = app.descendants(matching: .any).matching(identifier: "settings-contact-support").firstMatch
        for _ in 0..<4 {
            if support.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(support.isHittable)
        XCTAssertFalse(app.buttons["Support Spendy"].exists)
        XCTAssertFalse(app.links["Buy me a coffee"].exists)
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
