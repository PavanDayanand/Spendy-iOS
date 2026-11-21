import SwiftUI
import XCTest
@testable import Spendy

@MainActor final class AdaptiveLayoutTests: XCTestCase {
    func testRecentActivityReservesThreeRowsAndDockClearance() {
        for height: CGFloat in [640, 740, 874] {
            let offset = SpendyAdaptiveLayout.activityRestingOffset(totalHeight: height, bottomInset: 34)
            XCTAssertGreaterThanOrEqual(height - offset, 384,
                "Safe-area changes must not shrink the three-row activity card.")
            XCTAssertGreaterThanOrEqual(offset, 0)
        }
        XCTAssertEqual(SpendyAdaptiveLayout.activityRestingOffset(totalHeight: 300, bottomInset: 34), 0)
    }

    func testClosedDisplayStaysCompactInBothOrientations() {
        for size in [CGSize(width: 466, height: 678), CGSize(width: 678, height: 466)] {
            XCTAssertEqual(SpendyAdaptiveLayout.home(size: size, regularWidth: false), .compact)
        }
    }

    func testOpenPortraitUsesFlowAndLandscapeUsesAdjacentPanes() {
        XCTAssertEqual(SpendyAdaptiveLayout.home(size: CGSize(width: 669, height: 951), regularWidth: true), .portrait)
        XCTAssertEqual(SpendyAdaptiveLayout.home(size: CGSize(width: 951, height: 669), regularWidth: true), .arranged)
        XCTAssertFalse(SpendyAdaptiveLayout.usesColumns(size: CGSize(width: 744, height: 1133)))
        XCTAssertTrue(SpendyAdaptiveLayout.usesColumns(size: CGSize(width: 951, height: 669)))
    }

    func testPartialFoldAndNarrowMultitaskingRemainUsable() {
        XCTAssertEqual(SpendyAdaptiveLayout.home(size: CGSize(width: 669, height: 951), regularWidth: true, activeFold: true), .arranged)
        XCTAssertEqual(SpendyAdaptiveLayout.home(size: CGSize(width: 480, height: 669), regularWidth: true), .compact)
    }
}
