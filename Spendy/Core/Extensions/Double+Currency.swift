//
//  Double+Currency.swift
//  Spendy
//
//  Currency and Number Formatting Extension
//

import Foundation

// MARK: - Thread-Safe NumberFormatter Cache
enum SpendyNumberFormatterCache {
    private static var formatters: [Int: NumberFormatter] = [:]
    private static let lock = NSLock()

    static func decimalFormatter(decimals: Int) -> NumberFormatter {
        lock.lock()
        defer { lock.unlock() }
        if let existing = formatters[decimals] {
            return existing
        }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = decimals
        f.maximumFractionDigits = decimals
        formatters[decimals] = f
        return f
    }
}

extension Double {
    /// Safely converts Double to Int without crashing on NaN, Infinity, or overflow
    var safeInt: Int {
        guard !self.isNaN && !self.isInfinite else { return 0 }
        if self > Double(Int.max) { return Int.max }
        if self < Double(Int.min) { return Int.min }
        return Int(self)
    }
    
    /// Formats a double value with a currency symbol (e.g., "$1,250.00" or "₹1,250.00")
    func formattedCurrency(symbol: String = "$", decimals: Int = 2) -> String {
        guard !self.isNaN && !self.isInfinite else { return "\(symbol)0" }
        let formatter = SpendyNumberFormatterCache.decimalFormatter(decimals: decimals)
        let formattedNumber = formatter.string(from: NSNumber(value: abs(self))) ?? String(format: "%.\(decimals)f", abs(self))
        let sign = self < 0 ? "-" : ""
        return "\(sign)\(symbol)\(formattedNumber)"
    }
    
    /// Formats a double value as a number with standard thousand separator commas (e.g. "1,250.00" or "1,250")
    func formattedNumber(decimals: Int = 2) -> String {
        guard !self.isNaN && !self.isInfinite else { return "0" }
        let formatter = SpendyNumberFormatterCache.decimalFormatter(decimals: decimals)
        return formatter.string(from: NSNumber(value: self)) ?? String(format: "%.\(decimals)f", self)
    }
    
    /// Formats with a clear +/- sign (e.g. "+$500.00" or "-$45.50")
    func formattedSignedCurrency(symbol: String = "$", decimals: Int = 2) -> String {
        guard !self.isNaN && !self.isInfinite else { return "\(symbol)0" }
        let formatter = SpendyNumberFormatterCache.decimalFormatter(decimals: decimals)
        let formattedNumber = formatter.string(from: NSNumber(value: abs(self))) ?? String(format: "%.\(decimals)f", abs(self))
        if self > 0 {
            return "+\(symbol)\(formattedNumber)"
        } else if self < 0 {
            return "-\(symbol)\(formattedNumber)"
        } else {
            return "\(symbol)\(formattedNumber)"
        }
    }
    
    /// Compact formatted amount for charts and cards (e.g., "$1.2k", "$450")
    func formattedCompactCurrency(symbol: String = "$") -> String {
        if abs(self) >= 1_000_000 {
            return String(format: "\(symbol)%.1fM", self / 1_000_000)
        } else if abs(self) >= 1_000 {
            return String(format: "\(symbol)%.1fk", self / 1_000)
        } else {
            return formattedCurrency(symbol: symbol, decimals: 0)
        }
    }
}

extension String {
    /// Formats an input number string with live thousand separator commas while preserving decimal places & trailing dots
    func formattedNumberStringWithCommas() -> String {
        let clean = self.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return "0" }
        
        if clean.contains(".") {
            let parts = clean.components(separatedBy: ".")
            let intPart = parts.first ?? "0"
            let decPart = parts.count > 1 ? parts[1] : ""
            
            let formatter = SpendyNumberFormatterCache.decimalFormatter(decimals: 0)
            let formattedInt = (Double(intPart).flatMap { formatter.string(from: NSNumber(value: $0)) }) ?? intPart
            if clean.hasSuffix(".") {
                return "\(formattedInt)."
            } else {
                return "\(formattedInt).\(decPart)"
            }
        } else {
            let formatter = SpendyNumberFormatterCache.decimalFormatter(decimals: 0)
            if let num = Double(clean) {
                return formatter.string(from: NSNumber(value: num)) ?? clean
            }
            return clean
        }
    }
}
