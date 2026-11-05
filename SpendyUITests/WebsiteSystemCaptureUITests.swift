import XCTest
import ObjectiveC

// Manual capture helper. Normal test runs skip this suite so they never change system UI.
final class WebsiteSystemCaptureUITests: XCTestCase {
    private var idleMethods: [(Method, IMP)] = []

    override func setUpWithError() throws {
        try super.setUpWithError()
        let environment = ProcessInfo.processInfo.environment
        try XCTSkipUnless(environment["SPENDY_CAPTURE_SYSTEM_UI"] == "1" || environment["TEST_RUNNER_SPENDY_CAPTURE_SYSTEM_UI"] == "1", "Enable the manual system screenshot capture explicitly.")
        // SpringBoard's open menus can remain animated. Skip the long idle wait
        // during this capture only, then restore XCTest's implementation in tearDown.
        guard let process = NSClassFromString("XCUIApplicationProcess") else { return }
        for name in ["waitForQuiescenceIncludingAnimationsIdle:", "waitForQuiescenceIncludingAnimationsIdle:isPreEvent:"] {
            guard let method = class_getInstanceMethod(process, NSSelectorFromString(name)) else { continue }
            idleMethods.append((method, method_getImplementation(method)))
            if method_getNumberOfArguments(method) == 3 {
                let skip: @convention(block) (AnyObject, Bool) -> Void = { _, _ in }
                method_setImplementation(method, imp_implementationWithBlock(skip))
            } else if method_getNumberOfArguments(method) == 4 {
                let skip: @convention(block) (AnyObject, Bool, Bool) -> Void = { _, _, _ in }
                method_setImplementation(method, imp_implementationWithBlock(skip))
            }
        }
    }

    override func tearDown() {
        for (method, original) in idleMethods { method_setImplementation(method, original) }
        idleMethods.removeAll()
        super.tearDown()
    }

    @MainActor func testCaptureInstalledSystemWidgets() {
        launchSampleLedger()
        showInstalledHomeWidget()
        capture("website-home-widgets")
        XCUIDevice.shared.perform(NSSelectorFromString("pressLockButton"))
        settle(1)
        XCUIDevice.shared.press(.home)
        settle(2)
        capture("website-lock-widgets")
    }

    @MainActor func testCaptureSiriRequest() {
        launchSampleLedger()
        XCUIDevice.shared.press(.home)
        settle(1)
        XCUIDevice.shared.siriService.activate(voiceRecognitionText: "Add expense in Spendy")
        settle(2)
        capture("website-siri-add-request")
        settle(3)
        capture("website-siri-add-response")
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        print("SIRI_CAPTURE_STATE_START\n" + springboard.debugDescription + "\nSIRI_CAPTURE_STATE_END")
    }

    @MainActor private func launchSampleLedger() {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDY_UI_TEST_MODE"] = "website-screenshots"
        app.launchEnvironment["SPENDY_UI_TEST_APPEARANCE"] = ProcessInfo.processInfo.environment["SPENDY_CAPTURE_APPEARANCE"] ?? ProcessInfo.processInfo.environment["TEST_RUNNER_SPENDY_CAPTURE_APPEARANCE"] ?? "light"
        app.launchEnvironment["SPENDY_CAPTURE_SYSTEM_WIDGET_DATA"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["home-profile"].waitForExistence(timeout: 20))
        settle(3)
    }

    @MainActor private func showInstalledHomeWidget() {
        XCUIDevice.shared.press(.home)
        settle(1)
        XCUIDevice.shared.press(.home)
        settle(1)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        func widgetVisible() -> Bool {
            springboard.icons.matching(NSPredicate(format: "label == %@ AND value CONTAINS %@", "Spendy", "Widget")).allElementsBoundByIndex.contains {
                $0.frame.minX >= 0 && $0.frame.maxX <= 403 && $0.frame.width > 300
            }
        }
        if !widgetVisible() {
            for _ in 0..<3 { springboard.swipeRight(); settle(0.5) }
            for _ in 0..<5 {
                if widgetVisible() { break }
                springboard.swipeLeft()
                settle(0.8)
            }
        }
        XCTAssertTrue(widgetVisible(), "Install the real medium Quick Actions widget before capture.")
        settle(3)
    }

    @MainActor private func settle(_ seconds: TimeInterval) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    @MainActor private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
