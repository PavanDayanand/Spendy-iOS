import Foundation

/// A second contrast pass must corroborate a mistaken currency glyph; never strip a leading 7 by itself.
enum ReceiptOCRCurrencyRepair {
    static func isAmbiguous(_ text: String) -> Bool {
        text.range(of: #"^\s*[R7·$]\s*[0-9][0-9,.]*\s*$"#, options: .regularExpression) != nil
    }

    static func repair(_ text: String, corroborating other: String?) -> String {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isAmbiguous(text), let other = other?.trimmingCharacters(in: .whitespacesAndNewlines),
              let originalFirst = text.first, let otherFirst = other.first else { return text }
        let originalSuffix = String(text.dropFirst()).trimmingCharacters(in: .whitespaces)
        let otherSuffix = String(other.dropFirst()).trimmingCharacters(in: .whitespaces)
        let symbols: Set<Character> = ["₹", "R", "·", "$"]
        if symbols.contains(originalFirst), originalSuffix == otherSuffix,
           symbols.contains(otherFirst) || otherFirst == "7" {
            return "₹" + originalSuffix
        }
        if originalFirst == "7", symbols.contains(otherFirst), originalSuffix == otherSuffix {
            return "₹" + otherSuffix
        }
        return text
    }
}
