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

    @MainActor func testBlueUsesWhiteAndBrightPresetsUseBlack() {
        XCTAssertTrue(SpendyAccentPreset.blue.usesLightForeground)
        for preset in [SpendyAccentPreset.green, .pink, .yellow, .white] {
            XCTAssertFalse(preset.usesLightForeground, preset.title)
        }
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
            let ratio = preset.usesLightForeground ? 1.05 / (luminance + 0.05) : (luminance + 0.05) / 0.05
            XCTAssertGreaterThanOrEqual(ratio, 4.5, preset.title)
            var foreground: CGFloat = 0
            XCTAssertTrue(UIColor(preset.foreground).getWhite(&foreground, alpha: nil))
            XCTAssertEqual(foreground, preset.usesLightForeground ? 1 : 0, accuracy: 0.001)
        }
    }

    @MainActor func testControlTintsStayReadableInBothAppearances() {
        func luminance(_ color: UIColor, style: UIUserInterfaceStyle) -> Double {
            let resolved = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            XCTAssertTrue(resolved.getRed(&r, green: &g, blue: &b, alpha: &a))
            func linear(_ component: CGFloat) -> Double {
                let value = Double(component)
                return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
        }
        for preset in SpendyAccentPreset.allCases {
            let switchLuminance = luminance(UIColor(preset.switchTint), style: .light)
            XCTAssertGreaterThanOrEqual(1.05 / (switchLuminance + 0.05), 3, preset.title)
            for style in [UIUserInterfaceStyle.light, .dark] {
                let background = style == .light ? 1.0 : 0.05
                let value = luminance(UIColor(preset.contentTint), style: style)
                XCTAssertGreaterThanOrEqual((max(value, background) + 0.05) / (min(value, background) + 0.05), 4.5, preset.title)
                let fill = luminance(UIColor(preset.selectionFill), style: style)
                let foreground = luminance(UIColor(preset.selectionForeground), style: style)
                XCTAssertGreaterThanOrEqual((max(fill, foreground) + 0.05) / (min(fill, foreground) + 0.05), 4.5, preset.title)
            }
        }
    }

}
