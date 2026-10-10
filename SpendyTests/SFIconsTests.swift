import XCTest
import UIKit
@testable import Spendy

final class SFIconsTests: XCTestCase {
    func testUnavailableSavedSymbolHasVisibleFallback() {
        let resolved = SFIcons.symbol(named: "spendy.nonexistent.symbol")
        XCTAssertEqual(resolved, "square.grid.2x2.fill")
        XCTAssertNotNil(UIImage(systemName: resolved))
        XCTAssertEqual(SFIcons.symbol(named: "cart.fill"), "cart.fill")
    }

    func testPickerRemovesUnavailableAndDuplicateChoices() {
        let symbols = SFIcons.availableSymbols(["cart.fill", "spendy.nonexistent.symbol", "", "cart.fill", "banknote.fill"])
        XCTAssertEqual(symbols, ["cart.fill", "banknote.fill"])
    }
}
