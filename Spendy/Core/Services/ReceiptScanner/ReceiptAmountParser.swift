import Foundation
import CoreGraphics

/// Extract monetary evidence before selecting a total. Identifiers never participate.
enum ReceiptAmountParser {
    struct Line {
        let text: String
        var bounds: CGRect = .zero
        var confidence: Float = 1
    }

    struct Candidate {
        let amount: Double
        let priority: Int
        let evidence: String
        var bounds: CGRect = .zero
    }

    static func isIdentifierLine(_ text: String) -> Bool {
        matches(#"\b(account|acct|a/c|iban|ifsc|swift|routing|card|upi\s*(id|ref|reference|transaction)|utr|rrn|reference|ref|transaction\s*(id|no|number)|txn\s*(id|no|number)|invoice\s*(id|no|number)|order\s*(id|no|number)|phone|mobile|tel|gstin|tax\s*id|date|time)\b|[\w.+-]+@[\w.-]+|[x*•●]{2,}\s*\d"#, in: text)
    }

    static func isPaymentScreenshot(_ text: String) -> Bool {
        matches(#"\b(phonepe|paytm|google pay|gpay|upi|paid to|received from|transaction successful|payment successful|payment completed)\b"#, in: text)
    }

    static func total(in texts: [String]) -> Double {
        total(in: texts.map { Line(text: $0) })
    }

    static func total(in lines: [Line]) -> Double {
        let candidates = candidates(in: lines)
        guard let priority = candidates.map(\.priority).max() else { return 0 }
        let best = candidates.filter { $0.priority == priority }
        let amounts = Set(best.map(\.amount))
        if amounts.count == 1 { return amounts.first! }
        // Payment apps often present the amount in a large heading without a total label.
        // Require a clear size difference; never choose the largest numeric value.
        if isPaymentScreenshot(lines.map(\.text).joined(separator: "\n")),
           let prominent = best.max(by: { $0.bounds.height < $1.bounds.height }),
           prominent.bounds.height > 0, prominent.bounds.midY > 0.3,
           best.filter({ $0.amount != prominent.amount }).allSatisfy({
               $0.bounds.height > 0 && prominent.bounds.height >= $0.bounds.height * 1.5
           }) {
            return prominent.amount
        }
        return 0
    }

    static func candidates(in texts: [String]) -> [Candidate] {
        candidates(in: texts.map { Line(text: $0) })
    }

    static func candidates(in lines: [Line]) -> [Candidate] {
        let currency = #"(?:[$€£₹¥₩]|INR|USD|EUR|GBP|AED|CHF|AUD|CAD|SGD|NZD|Rs\.?)"#
        let number = #"(?:[0-9]{1,3}(?:,[0-9]{2})*,[0-9]{3}|[0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)(?:\.[0-9]{1,2})?"#
        let pattern = #"(?<![\w/*:#,.-])(?:"# + currency + #"\s*)?("# + number + #")(?![\w/*:,.%-])"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return [] }
        let paymentScreenshot = isPaymentScreenshot(lines.map(\.text).joined(separator: "\n"))
        var candidates: [Candidate] = []
        for (index, line) in lines.enumerated() {
            let text = line.text
            guard line.confidence >= 0.3, !isIdentifierLine(text) else { continue }
            let previous = index > 0 ? lines[index - 1].text : ""
            let currentPriority = labelPriority(text)
            guard currentPriority >= 0 else { continue }
            let previousHasNumber = matches(#"\d"#, in: previous)
            let previousPriority = !previousHasNumber && !isIdentifierLine(previous) ? labelPriority(previous) : 0
            // Exclude a value split onto the next OCR line after a balance/identifier label.
            if currentPriority == 0 && (isIdentifierLine(previous) || previousPriority < 0) { continue }
            let ns = text as NSString
            let tokens = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
            let hasPrefixedMoney = tokens.contains { hasCurrency(ns.substring(with: $0.range)) }
            let hasDecimals = tokens.contains { ns.substring(with: $0.range(at: 1)).contains(".") }
            for token in tokens {
                let numberText = ns.substring(with: token.range(at: 1))
                let explicitlyMonetary = hasCurrency(ns.substring(with: token.range))
                // "Total 3 items ₹900" means ₹900, not 3. Avoid quantities on total lines.
                if hasPrefixedMoney && !explicitlyMonetary { continue }
                if !hasPrefixedMoney && hasDecimals && !numberText.contains(".") { continue }
                let label = max(currentPriority, previousPriority)
                let monetary = explicitlyMonetary || (!previousHasNumber && hasCurrency(previous))
                let prominentPaymentNumber = paymentScreenshot && line.bounds.height >= 0.035 && line.confidence >= 0.7
                    && matches(#"^\s*[0-9,.]+\s*$"#, in: text) && numberText.filter(\.isNumber).count <= 6
                guard label > 0 || monetary || numberText.contains(".") || prominentPaymentNumber,
                      let amount = Double(numberText.replacingOccurrences(of: ",", with: "")),
                      amount.isFinite, amount > 0, amount <= 1_000_000_000 else { continue }
                let context = !previousHasNumber && !isIdentifierLine(previous) ? previous + " · " + text : text
                candidates.append(Candidate(amount: amount, priority: label > 0 ? label : monetary ? 5 : 1,
                    evidence: String(context.prefix(200)), bounds: line.bounds))
            }
        }
        return candidates
    }

    static func hasCurrency(_ text: String) -> Bool {
        matches(#"[$€£₹¥₩]|\b(INR|USD|EUR|GBP|AED|CHF|AUD|CAD|SGD|NZD|Rs\.?)\b"#, in: text)
    }

    private static func labelPriority(_ text: String) -> Int {
        if matches(#"\b(sub[ -]?total|tax|vat|change|cash tendered|discount|cashback|reward|coupon|offer|available balance|balance available|bank balance|wallet balance|closing balance|opening balance|credit limit|paid by|debited from|credited to|from account)\b"#, in: text) { return -1 }
        if matches(#"\b(grand total|total due|total amount|amount paid|amount due|final total|net amount|final payable|amount payable)\b"#, in: text) { return 30 }
        if matches(#"\b(total|paid|payment amount|bal due|balance due|sent|received|debited|credited|payment successful|transaction successful|payment completed)\b"#, in: text) { return 20 }
        return 0
    }

    private static func matches(_ pattern: String, in text: String) -> Bool {
        text.range(of: "(?i)" + pattern, options: .regularExpression) != nil
    }
}

enum ReceiptPaymentStatus: Equatable {
    case unknown, completed, pending, failed

    static func detect(in text: String) -> Self {
        guard ReceiptAmountParser.isPaymentScreenshot(text) else { return .unknown }
        if text.range(of: #"(?i)\b(payment|transaction|transfer)\s+(failed|declined|cancelled)|\b(payment unsuccessful|couldn't complete|could not complete)\b|(?m)^\s*(failed|declined|cancelled)\s*$"#, options: .regularExpression) != nil { return .failed }
        if text.range(of: #"(?i)\b(payment|transaction|transfer)\s+(pending|processing|in progress)|\b(awaiting confirmation|payment initiated)\b|(?m)^\s*(pending|processing|in progress)\s*$"#, options: .regularExpression) != nil { return .pending }
        if text.range(of: #"(?i)\b(successful|completed|paid|sent|received)\b"#, options: .regularExpression) != nil { return .completed }
        return .unknown
    }
}
