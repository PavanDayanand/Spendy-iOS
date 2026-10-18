import Foundation

/// Canonical decimal text for the native account keyboard, including localized digits.
enum AccountBalanceEntry {
    static func normalized(_ text: String, locale: Locale) -> String? {
        let localized = text.replacingOccurrences(of: locale.decimalSeparator ?? ".", with: ".")
        var canonical = ""
        for character in localized {
            if character == "." {
                canonical.append(".")
            } else if let digit = character.wholeNumberValue, (0...9).contains(digit) {
                canonical.append(String(digit))
            } else {
                return nil
            }
        }
        let parts = canonical.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count <= 2, parts[0].count <= 10,
              parts.count == 1 || parts[1].count <= 2 else { return nil }
        guard !canonical.isEmpty else { return "" }
        let integer = String(parts[0].drop(while: { $0 == "0" }))
        return (integer.isEmpty ? "0" : integer) + (parts.count == 2 ? "." + parts[1] : "")
    }
}
