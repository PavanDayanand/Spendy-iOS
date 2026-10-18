import XCTest
@testable import Spendy

final class AccountBalanceEntryTests: XCTestCase {
    func testLocalizedDecimalEntry() {
        XCTAssertEqual(AccountBalanceEntry.normalized("1250.50", locale: Locale(identifier: "en_IN")), "1250.50")
        XCTAssertEqual(AccountBalanceEntry.normalized("1250,50", locale: Locale(identifier: "de_DE")), "1250.50")
        XCTAssertEqual(AccountBalanceEntry.normalized("١٢٫٥٠", locale: Locale(identifier: "ar_EG")), "12.50")
        XCTAssertEqual(AccountBalanceEntry.normalized(".5", locale: Locale(identifier: "en_US")), "0.5")
        XCTAssertEqual(AccountBalanceEntry.normalized("", locale: Locale(identifier: "en_US")), "")
    }

    func testRejectsInvalidOrOverPrecisionInput() {
        for text in ["12.500", "12..5", "NaN", "1e5", "12345678901", "12x"] {
            XCTAssertNil(AccountBalanceEntry.normalized(text, locale: Locale(identifier: "en_US")), text)
        }
    }
}
