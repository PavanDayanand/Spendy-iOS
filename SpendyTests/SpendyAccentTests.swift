import XCTest
import UIKit
@testable import Spendy

final class SpendyAccentTests: XCTestCase {
    @MainActor private func store() throws -> (ExpenseStore, URL) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("store.json")
        return (ExpenseStore(storageURL: url, startsServices: false), url)
    }

    @MainActor func testAccentSurvivesRelaunchAndBackupRestore() throws {
        let (original, url) = try store()
        XCTAssertEqual(original.accentPreset, .white)
        original.accentPreset = .pink
        original.flushPendingSave()
        XCTAssertEqual(ExpenseStore(storageURL: url, startsServices: false).accentPreset, .pink)
        let backup = try XCTUnwrap(original.exportJSONData())
        let (destination, destinationURL) = try store()
        XCTAssertTrue(destination.importJSONData(data: backup))
        XCTAssertEqual(destination.accentPreset, .pink)
        destination.flushPendingSave()
        XCTAssertEqual(ExpenseStore(storageURL: destinationURL, startsServices: false).accentPreset, .pink)
    }

    @MainActor func testOlderAndUnknownAccentBackupsStillRestoreTheLedger() throws {
        let (original, _) = try store()
        original.userName = "Restored user"
        original.accentPreset = .green
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(original.exportJSONData())) as? [String: Any])
        payload.removeValue(forKey: "appAccent")
        let (destination, _) = try store()
        XCTAssertTrue(destination.importJSONData(data: try JSONSerialization.data(withJSONObject: payload)))
        XCTAssertEqual(destination.accentPreset, .white)
        XCTAssertEqual(destination.userName, "Restored user")
        payload["appAccent"] = "future-preset"
        XCTAssertTrue(destination.importJSONData(data: try JSONSerialization.data(withJSONObject: payload)))
        XCTAssertEqual(destination.accentPreset, .white)
        XCTAssertEqual(destination.userName, "Restored user")
    }

    @MainActor func testEveryPresetHasReadableLabelContrast() {
        for preset in SpendyAccentPreset.allCases {
            let color = UIColor(preset.fill)
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            XCTAssertTrue(color.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
            func linear(_ component: CGFloat) -> Double {
                let value = Double(component)
                return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
            }
            let luminance = 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
            XCTAssertGreaterThanOrEqual((luminance + 0.05) / 0.05, 4.5, preset.title)
        }
    }
}
