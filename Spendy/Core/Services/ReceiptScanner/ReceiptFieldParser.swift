import Foundation
import CoreGraphics

/// Deterministic merchant and date extraction from OCR text and its page geometry.
enum ReceiptFieldParser {
    typealias Line = ReceiptAmountParser.Line

    static func merchant(in lines: [Line], payment: Bool) -> String {
        if payment {
            let incoming = lines.contains { $0.text.range(of: #"(?i)received from|money received|payment received"#, options: .regularExpression) != nil }
            let labels = incoming
                ? #"(?i)^(?:received from|received money from|from)\s*[:\-]?\s*"#
                : #"(?i)^(?:paid to|payment to|transfer to|sent to|to)\s*[:\-]?\s*"#
            for (index, line) in lines.enumerated() {
                guard let range = line.text.range(of: labels, options: .regularExpression) else { continue }
                var name = String(line.text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                if name.isEmpty, index + 1 < lines.count { name = lines[index + 1].text }
                if eligible(name), !ReceiptAmountParser.hasCurrency(name) { return clean(name) }
            }
            return "Merchant"
        }

        // Use the receipt's own metadata to ignore handwriting on the surrounding desk.
        let anchor = lines.first { $0.text.range(of: #"(?i)^(?:tax invoice|invoice|bill no|phone|mob|gstin|date)\b|^\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4}\b"#, options: .regularExpression) != nil }
        let header = lines.filter { line in
            guard eligible(line.text) else { return false }
            guard let anchor, anchor.bounds != .zero, line.bounds != .zero else { return true }
            return line.bounds.midY > anchor.bounds.midY &&
                abs(line.bounds.midX - anchor.bounds.midX) < max(0.12, line.bounds.width / 2)
        }
        guard let first = header.first else { return "Merchant" }
        var name = first.text
        if let next = header.dropFirst().first,
           next.text.range(of: #"(?i)^(market|supermarket|restaurant|cafe|bakery|stores?)$"#, options: .regularExpression) != nil,
           (first.bounds == .zero || abs(first.bounds.midY - next.bounds.midY) < 0.06) {
            name += " " + next.text
        }
        return clean(name)
    }

    private static func eligible(_ text: String) -> Bool {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.filter(\.isLetter).count >= 3, !ReceiptAmountParser.isIdentifierLine(t),
              !ReceiptAmountParser.hasCurrency(t) else { return false }
        return t.range(of: #"(?i)\b(invoice|receipt|total|subtotal|amount|tax|gst|qty|quantity|item|date|time|token|discount|balance|cash|customer|delivery|not available|welcome|thank|powered|completed|successful|pending|failed|banking name)\b|\b(ground|floor|layout|railway|road|street|near|arcade|stage|bangalore|bengaluru|phone|mob|email|call|whatsapp)\b|^counter\b|^no\.?\s*\d|\b\d{6}\b"#, options: .regularExpression) == nil
    }

    private static func clean(_ text: String) -> String {
        text.replacingOccurrences(of: #"[#*]+.*$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines).capitalized
    }

    static func date(in lines: [Line], dayFirst: Bool) -> Date? {
        let numeric = try! NSRegularExpression(pattern: #"(?<!\d)(\d{1,4})[/.-](\d{1,2})[/.-](\d{2,4})(?!\d)"#)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        for line in lines {
            let ns = line.text as NSString
            for match in numeric.matches(in: line.text, range: NSRange(location: 0, length: ns.length)) {
                let values = (1...3).map { Int(ns.substring(with: match.range(at: $0)))! }
                let yearFirst = match.range(at: 1).length == 4
                var year = yearFirst ? values[0] : values[2]
                if !yearFirst && match.range(at: 3).length == 2 { year += 2000 }
                guard (2000...2099).contains(year) else { continue }
                let day = yearFirst ? values[2] : dayFirst ? values[0] : values[1]
                let month = yearFirst ? values[1] : dayFirst ? values[1] : values[0]
                let components = DateComponents(year: year, month: month, day: day)
                if let date = calendar.date(from: components),
                   calendar.dateComponents([.year, .month, .day], from: date) == components { return date }
            }
            let pattern = #"\b(?:\d{1,2}\s+[A-Za-z]{3,9},?\s+\d{4}|[A-Za-z]{3,9}\s+\d{1,2},?\s+\d{4})\b"#
            guard let range = line.text.range(of: pattern, options: .regularExpression) else { continue }
            let text = String(line.text[range]).replacingOccurrences(of: ",", with: "")
            for format in ["d MMM yyyy", "d MMMM yyyy", "MMM d yyyy", "MMMM d yyyy"] {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.calendar = calendar
                formatter.dateFormat = format
                formatter.isLenient = false
                if let date = formatter.date(from: text) { return date }
            }
        }
        return nil
    }
}
