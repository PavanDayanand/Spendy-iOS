import XCTest
import SwiftUI
import UIKit
@testable import Spendy

final class MonochromeAppearanceTests: XCTestCase {
    @MainActor private func store() throws -> (ExpenseStore, URL) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("store.json")
        return (ExpenseStore(storageURL: url, startsServices: false), url)
    }

    private let retiredSettings: [String: Any] = [
        "appAccent": "pink", "isMonoIconMode": false,
        "isGradientBackgroundEnabled": true, "homeGradientStyle": "indigo",
        "topGradientColorHex": "#007AFF", "topGradientHue": 0.6,
        "topGradientBrightness": 0.85, "profileColorHex": "#FF0000"
    ]

    @MainActor func testLegacyColorBackupPreservesLedgerAndDisplayMode() throws {
        let (original, _) = try store()
        original.userName = "Restored user"
        original.appearanceMode = .light
        original.accounts = [Account(id: "cash", label: "Cash", colorHex: "#FF0000", openingBalance: 100)]
        original.transactions = [Transaction(title: "Lunch", amount: 12, categoryId: "restaurants", accountId: "cash")]
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(original.exportJSONData())) as? [String: Any])
        payload.merge(retiredSettings) { _, legacy in legacy }
        let (destination, url) = try store()
        XCTAssertTrue(destination.importJSONData(data: try JSONSerialization.data(withJSONObject: payload)))
        destination.flushPendingSave()
        let reloaded = ExpenseStore(storageURL: url, startsServices: false)
        XCTAssertEqual(reloaded.userName, "Restored user")
        XCTAssertEqual(reloaded.appearanceMode, .light)
        XCTAssertEqual(reloaded.accounts.first?.openingBalance, 100)
        XCTAssertEqual(reloaded.transactions.first?.amount, 12)
        let exported = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(reloaded.exportJSONData())) as? [String: Any])
        for key in retiredSettings.keys { XCTAssertNil(exported[key], key) }
    }

    @MainActor func testLegacyDiskSaveLoadsWithoutReapplyingColorPreferences() throws {
        let (original, url) = try store()
        original.userName = "Existing user"
        original.appearanceMode = .system
        original.flushPendingSave()
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        payload.merge(retiredSettings) { _, legacy in legacy }
        try JSONSerialization.data(withJSONObject: payload).write(to: url)
        let reloaded = ExpenseStore(storageURL: url, startsServices: false)
        XCTAssertNil(reloaded.loadError)
        XCTAssertEqual(reloaded.userName, "Existing user")
        XCTAssertEqual(reloaded.appearanceMode, .system)
        reloaded.flushPendingSave()
    }

    @MainActor func testLegacyItemColorsRenderAsNeutralContrastingBadges() {
        for scheme in [ColorScheme.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: scheme == .light ? .light : .dark)
            for color in [Color.red, .green, .blue, .yellow] {
                let paint = SpendyIconPaint.resolve(color, scheme: scheme, mono: false, prominent: true)
                func components(_ color: Color) -> (CGFloat, CGFloat, CGFloat) {
                    let resolved = UIColor(color).resolvedColor(with: traits)
                    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                    XCTAssertTrue(resolved.getRed(&r, green: &g, blue: &b, alpha: &a))
                    XCTAssertEqual(r, g, accuracy: 0.001)
                    XCTAssertEqual(g, b, accuracy: 0.001)
                    return (r, g, b)
                }
                let fill = components(paint.fill).0
                let glyph = components(paint.glyph).0
                XCTAssertEqual(abs(fill - glyph), 1, accuracy: 0.001)
            }
        }
    }
}
