import XCTest
import SwiftUI
@testable import Spendy

final class HomeGradientTests: XCTestCase {
    @MainActor private func renderedPixels(style: HomeGradientStyle, phase: Double, moving: Bool) throws -> [UInt8] {
        let view = HomeGradientCanvas(style: style, phase: phase, motionEnabled: moving)
            .frame(width: 201, height: 437)
            .environment(\.colorScheme, .dark)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.cgImage)
        return Array(try XCTUnwrap(image.dataProvider?.data) as Data)
    }

    @MainActor func testWaveMovesLoopsAndHonoursStillMode() throws {
        for style in HomeGradientStyle.allCases {
            let first = try renderedPixels(style: style, phase: 0, moving: true)
            let quarter = try renderedPixels(style: style, phase: .pi / 2, moving: true)
            let loop = try renderedPixels(style: style, phase: .pi * 2, moving: true)
            XCTAssertNotEqual(first, quarter, "\(style.title) should move")
            XCTAssertEqual(first.count, loop.count)
            let maximumLoopDifference = zip(first, loop).map { abs(Int($0) - Int($1)) }.max() ?? 0
            XCTAssertLessThanOrEqual(maximumLoopDifference, 2, "\(style.title) should loop seamlessly")
            XCTAssertEqual(try renderedPixels(style: style, phase: 0, moving: false),
                           try renderedPixels(style: style, phase: .pi / 2, moving: false))
        }
    }

    @MainActor private func store() throws -> (ExpenseStore, URL) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("store.json")
        return (ExpenseStore(storageURL: url, startsServices: false), url)
    }

    @MainActor func testStyleAndEnabledStateSurviveRelaunchAndBackupRestore() throws {
        let (original, url) = try store()
        original.homeGradientStyle = .indigo
        original.isGradientBackgroundEnabled = false
        original.flushPendingSave()
        let reloaded = ExpenseStore(storageURL: url, startsServices: false)
        XCTAssertEqual(reloaded.homeGradientStyle, .indigo)
        XCTAssertFalse(reloaded.isGradientBackgroundEnabled)
        let (restored, restoredURL) = try store()
        XCTAssertTrue(restored.importJSONData(data: try XCTUnwrap(original.exportJSONData())))
        restored.flushPendingSave()
        let restoredReloaded = ExpenseStore(storageURL: restoredURL, startsServices: false)
        XCTAssertEqual(restoredReloaded.homeGradientStyle, .indigo)
        XCTAssertFalse(restoredReloaded.isGradientBackgroundEnabled)
    }

    @MainActor func testOlderAndUnknownStyleBackupsKeepExistingData() throws {
        let (original, _) = try store()
        original.userName = "Gradient migration check"
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: try XCTUnwrap(original.exportJSONData())) as? [String: Any])
        payload.removeValue(forKey: "homeGradientStyle")
        let (restored, _) = try store()
        XCTAssertTrue(restored.importJSONData(data: try JSONSerialization.data(withJSONObject: payload)))
        XCTAssertEqual(restored.homeGradientStyle, .blueAura)
        XCTAssertEqual(restored.userName, original.userName)
        payload["homeGradientStyle"] = "future-style"
        XCTAssertTrue(restored.importJSONData(data: try JSONSerialization.data(withJSONObject: payload)))
        XCTAssertEqual(restored.homeGradientStyle, .blueAura)
        XCTAssertEqual(restored.userName, original.userName)
    }
}
