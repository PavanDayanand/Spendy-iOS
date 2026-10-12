//
//  ReceiptScannerEngine.swift
//  Spendy
//
//  High-Performance On-Device Machine Learning OCR & Semantic Receipt Parser
//  Leveraging Apple's Vision Framework (VNRecognizeTextRequest).
//  Extracts Merchant Name, Total Amount, Currency, Date, Category, Payment Account, and Line Items.
//

import SwiftUI
import Vision
import Foundation
import CoreImage

// MARK: - Receipt Line Item
struct ReceiptLineItem: Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var amount: Double
    var isSelected: Bool = true
}

// MARK: - Receipt Type Classification
enum ReceiptType: String, CaseIterable {
    case physicalReceipt = "Receipt"
    case paymentScreenshot = "Payment Screenshot"
    case invoice = "Invoice / Bill"
    case general = "Document"
}

// MARK: - Parsed Receipt Result
struct ReceiptScanResult: Identifiable, Equatable {
    var id: UUID = UUID()
    var merchantName: String
    var totalAmount: Double
    var currencySymbol: String
    var date: Date
    var suggestedCategoryId: String?
    var suggestedAccountId: String?
    var confidence: Double
    var lineItems: [ReceiptLineItem]
    var rawRecognizedText: String
    var receiptType: ReceiptType
    var originalImage: UIImage?
    var wasAssistedByAppleIntelligence: Bool = false
    var transactionType: TransactionType = .expense
    var paymentStatus: ReceiptPaymentStatus = .unknown
    var hasDetectedDate: Bool = true
    
    var formattedAmount: String {
        String(format: "%.2f", totalAmount)
    }
}

// MARK: - Receipt Scanner Engine
final class ReceiptScannerEngine {
    static let shared = ReceiptScannerEngine()
    
    private init() {}
    
    /// Scans a UIImage and returns semantic structured receipt data
    func scanImage(
        _ image: UIImage,
        categories: [Category],
        accounts: [Account],
        defaultCurrencySymbol: String = "$",
        onIntelligenceStarted: (() -> Void)? = nil
    ) async -> ReceiptScanResult {
        await scanImages(
            [image],
            categories: categories,
            accounts: accounts,
            defaultCurrencySymbol: defaultCurrencySymbol,
            onIntelligenceStarted: onIntelligenceStarted
        )
    }

    /// Document camera scans can contain several pages; read all of them before parsing.
    func scanImages(
        _ images: [UIImage],
        categories: [Category],
        accounts: [Account],
        defaultCurrencySymbol: String = "$",
        onIntelligenceStarted: (() -> Void)? = nil
    ) async -> ReceiptScanResult {
        guard let firstImage = images.first else {
            return fallbackEmptyResult(currency: defaultCurrencySymbol, image: UIImage())
        }

        var recognizedLines: [RecognizedLine] = []
        for image in images {
            let cgImage = image.cgImage ?? image.ciImage.flatMap {
                CIContext().createCGImage($0, from: $0.extent)
            }
            guard let cgImage else { continue }
            let orientation = CGImagePropertyOrientation(image.imageOrientation)
            var pageLines = await performVisionOCR(on: cgImage, orientation: orientation)
            let indianPayment = pageLines.contains { $0.text.range(of: #"(?i)phonepe|paytm|\bupi\b|\binr\b"#, options: .regularExpression) != nil }
            if indianPayment && pageLines.contains(where: { ReceiptOCRCurrencyRepair.isAmbiguous($0.text) }) {
                let inverted = CIImage(cgImage: cgImage).applyingFilter("CIColorInvert")
                if let invertedImage = CIContext().createCGImage(inverted, from: inverted.extent) {
                    let secondPass = await performVisionOCR(on: invertedImage, orientation: orientation)
                    pageLines = pageLines.map { line in
                        let counterpart = secondPass.min { a, b in
                            abs(a.boundingBox.midY - line.boundingBox.midY) < abs(b.boundingBox.midY - line.boundingBox.midY)
                        }
                        let matchingText = counterpart.flatMap { abs($0.boundingBox.midY - line.boundingBox.midY) < 0.02 ? $0.text : nil }
                        let repaired = ReceiptOCRCurrencyRepair.repair(line.text, corroborating: matchingText)
                        let unresolved = repaired == line.text && line.text.hasPrefix("7") && ReceiptOCRCurrencyRepair.isAmbiguous(line.text)
                        return RecognizedLine(text: repaired, boundingBox: line.boundingBox,
                            confidence: unresolved ? 0 : line.confidence, unresolvedCurrencyGlyph: unresolved)
                    }
                }
            }
            recognizedLines += pageLines
        }
        guard !recognizedLines.isEmpty else {
            return fallbackEmptyResult(currency: defaultCurrencySymbol, image: firstImage)
        }
        
        let fullText = recognizedLines.map { $0.text }.joined(separator: "\n")
        
        // 1. Detect Receipt Type
        let receiptType = detectReceiptType(from: recognizedLines, fullText: fullText)
        
        // 2. Extract Currency & Amount
        var (totalAmount, detectedCurrency) = extractTotalAmount(from: recognizedLines, defaultCurrency: defaultCurrencySymbol)
        
        let paymentStatus = ReceiptPaymentStatus.detect(in: fullText)
        var wasAssistedByAppleIntelligence = false
        if totalAmount == 0, paymentStatus != .pending, paymentStatus != .failed,
           !recognizedLines.contains(where: \.unresolvedCurrencyGlyph),
           let assistedAmount = await ReceiptIntelligenceFallback.amount(
               from: recognizedLines.map(\.text), onStarted: onIntelligenceStarted
           ) {
            totalAmount = assistedAmount
            wasAssistedByAppleIntelligence = true
        }

        // 3. Extract Merchant Name
        let merchantName = extractMerchantName(from: recognizedLines, receiptType: receiptType)
        
        // 4. Extract Date
        let detectedDate = extractDate(from: recognizedLines, dayFirst: detectedCurrency == "₹")
        let date = detectedDate ?? Date()
        
        // 5. Extract Line Items
        let lineItems = extractLineItems(from: recognizedLines, totalAmount: totalAmount)
        
        // 6. Match Category & Account
        let transactionType: TransactionType = receiptType == .paymentScreenshot && fullText.range(
            of: #"(?i)\b(received from|money received|payment received|(?m)^received$)\b"#,
            options: .regularExpression) != nil ? .income : .expense
        let suggestedCategory = matchCategory(merchant: merchantName, categories: categories.filter { $0.type == transactionType })
        let suggestedAccount = matchAccount(fullText: fullText, accounts: accounts)
        
        // Calculate Confidence score
        var confidenceScore = 0.5
        if totalAmount > 0 { confidenceScore += 0.25 }
        if !merchantName.isEmpty && merchantName != "Merchant" { confidenceScore += 0.15 }
        if !lineItems.isEmpty { confidenceScore += 0.10 }
        
        return ReceiptScanResult(
            merchantName: merchantName.isEmpty ? "Scanned Expense" : merchantName,
            totalAmount: totalAmount,
            currencySymbol: detectedCurrency,
            date: date,
            suggestedCategoryId: suggestedCategory?.id,
            suggestedAccountId: suggestedAccount?.id,
            confidence: min(1.0, confidenceScore),
            lineItems: lineItems,
            rawRecognizedText: fullText,
            receiptType: receiptType,
            originalImage: firstImage,
            wasAssistedByAppleIntelligence: wasAssistedByAppleIntelligence,
            transactionType: transactionType,
            paymentStatus: paymentStatus,
            hasDetectedDate: detectedDate != nil
        )
    }
    
    // MARK: - Vision OCR Runner
    private struct RecognizedLine {
        let text: String
        let boundingBox: CGRect
        let confidence: Float
        var unresolvedCurrencyGlyph: Bool = false
    }
    
    private func performVisionOCR(on cgImage: CGImage, orientation: CGImagePropertyOrientation) async -> [RecognizedLine] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil, let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                // Sort lines top to bottom (Vision Y is 0 at bottom, 1 at top -> descending Y), then left to right (ascending X)
                let sortedObservations = observations.sorted { obs1, obs2 in
                    let y1 = obs1.boundingBox.midY
                    let y2 = obs2.boundingBox.midY
                    if abs(y1 - y2) > 0.015 {
                        return y1 > y2 // Top first
                    }
                    return obs1.boundingBox.minX < obs2.boundingBox.minX // Left first
                }
                
                var lines: [RecognizedLine] = []
                for obs in sortedObservations {
                    if let topCandidate = obs.topCandidates(1).first {
                        let text = topCandidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !text.isEmpty {
                            lines.append(RecognizedLine(
                                text: text,
                                boundingBox: obs.boundingBox,
                                confidence: topCandidate.confidence
                            ))
                        }
                    }
                }
                
                continuation.resume(returning: lines)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.automaticallyDetectsLanguage = true
            request.customWords = ["PhonePe", "Paytm", "Google Pay", "UPI", "INR", "UTR", "Grand Total", "Debited", "Credited"]
            
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    // MARK: - Semantic Parsing Logic
    
    private func detectReceiptType(from lines: [RecognizedLine], fullText: String) -> ReceiptType {
        let lower = fullText.lowercased()
        if ReceiptAmountParser.isPaymentScreenshot(fullText) || lower.contains("payment completed") || lower.contains("apple pay") || lower.contains("venmo") ||
           lower.contains("zelle") || lower.contains("transaction successful") || lower.contains("paid to") ||
           lower.contains("gpay") || lower.contains("upi") || lower.contains("cash app") {
            return .paymentScreenshot
        }
        if lower.contains("invoice") || lower.contains("bill to") || lower.contains("due date") {
            return .invoice
        }
        return .physicalReceipt
    }
    
    private func extractMerchantName(from lines: [RecognizedLine], receiptType: ReceiptType) -> String {
        let excludedNoiseWords: Set<String> = [
            "tax invoice", "tax receipt", "receipt", "sales receipt", "cash receipt", "customer copy",
            "welcome", "store", "tel", "phone", "fax", "www", "http", "https", ".com", "order #",
            "order no", "invoice", "date", "time", "cashier", "register", "terminal", "table #",
            "guest", "server", "check #", "subtotal", "total", "amount", "change", "visa", "mastercard"
        ]
        
        if receiptType == .paymentScreenshot {
            let labels = #"(?i)^(?:paid to|payment to|transfer to|sent to|received from|received money from|to|from)\s*[:\-]?\s*"#
            for (index, line) in lines.enumerated() {
                let text = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard let range = text.range(of: labels, options: .regularExpression) else { continue }
                var name = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                if name.isEmpty, index + 1 < lines.count { name = lines[index + 1].text }
                guard name.count > 1, name.rangeOfCharacter(from: .letters) != nil,
                      !ReceiptAmountParser.isIdentifierLine(name), !ReceiptAmountParser.hasCurrency(name) else { continue }
                return cleanMerchantName(name)
            }
        }

        // Scan the top 6 lines for the most prominent brand / merchant name
        for line in lines.prefix(6) {
            let t = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = t.lowercased()
            
            // Skip lines with only digits/dates/special chars
            if t.count < 3 || t.rangeOfCharacter(from: CharacterSet.letters) == nil {
                continue
            }
            
            // Skip pure noise words
            var isNoise = false
            for noise in excludedNoiseWords {
                if lower == noise || lower.hasPrefix(noise + " ") || lower.hasPrefix(noise + ":") {
                    isNoise = true
                    break
                }
            }
            if isNoise || ReceiptAmountParser.isIdentifierLine(t) || ReceiptAmountParser.hasCurrency(t) { continue }
            if receiptType == .paymentScreenshot && lower.range(of: #"phonepe|paytm|google pay|gpay|successful|completed|pending|failed|payment|transaction|powered by|money received"#, options: .regularExpression) != nil { continue }
            
            // If line is an address or phone number, skip
            if lower.contains("street") || lower.contains("ave") || lower.contains("road") || lower.contains("blvd") || lower.contains("highway") || lower.contains("suite") {
                continue
            }
            
            return cleanMerchantName(t)
        }
        
        return "Merchant"
    }
    
    private func cleanMerchantName(_ name: String) -> String {
        var cleaned = name
        // Remove trailing punctuation or tax indicators
        cleaned = cleaned.replacingOccurrences(of: #"[#*]+.*$"#, with: "", options: .regularExpression)
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.capitalized
    }
    
    private func extractTotalAmount(from lines: [RecognizedLine], defaultCurrency: String) -> (Double, String) {
        let parsedLines = lines.map { ReceiptAmountParser.Line(text: $0.text, bounds: $0.boundingBox, confidence: $0.confidence) }
        let amount = ReceiptAmountParser.total(in: parsedLines)
        let evidence = ReceiptAmountParser.candidates(in: parsedLines)
            .filter { $0.amount == amount }.max(by: { $0.priority < $1.priority })?.evidence
        let currency = evidence.flatMap { detectCurrencySymbol(in: $0) } ?? defaultCurrency
        return (amount, currency)
    }
    
    private func detectCurrencySymbol(in text: String) -> String? {
        let symbols = ["$", "€", "£", "₹", "¥", "₩", "CHF", "AED", "AUD", "CAD", "SGD", "NZD", "kr", "zł", "R$"]
        if text.range(of: #"(?i)\b(INR|Rs\.?)\b"#, options: .regularExpression) != nil { return "₹" }
        for s in symbols {
            if text.contains(s) {
                return s
            }
        }
        return nil
    }
    
    private func extractNumbersWithDecimals(from text: String) -> [Double] {
        var results: [Double] = []
        // Match numbers like 12.99, $1,250.50, 45.00, 1500
        let pattern = #"(?<![\d/:-])(?:[\$€£₹¥]\s*)?((?:[0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)(?:\.[0-9]{1,2})?)(?![\d/:-])"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsStr = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsStr.length))
            for match in matches {
                if match.numberOfRanges > 1 {
                    let numStr = nsStr.substring(with: match.range(at: 1)).replacingOccurrences(of: ",", with: "")
                    if let val = Double(numStr) {
                        results.append(val)
                    }
                }
            }
        }
        return results
    }
    
    private func extractDate(from lines: [RecognizedLine], dayFirst: Bool) -> Date? {
        let datePatterns = [
            #"\b(\d{1,2})[\/\.-](\d{1,2})[\/\.-](\d{2,4})\b"#, // MM/DD/YYYY or DD/MM/YYYY
            #"\b(\d{4})[\/\.-](\d{1,2})[\/\.-](\d{1,2})\b"#, // YYYY-MM-DD
            #"\b(\d{1,2})\s+([A-Za-z]{3,9}),?\s+(\d{4})\b"#,
            #"\b([A-Za-z]{3,9})\s+(\d{1,2}),?\s+(\d{4})\b"#   // Jan 15, 2026
        ]
        
        let formatters: [DateFormatter] = {
            let numericFormats = dayFirst
                ? ["dd/MM/yyyy", "dd-MM-yyyy", "MM/dd/yyyy", "MM-dd-yyyy"]
                : ["MM/dd/yyyy", "MM-dd-yyyy", "dd/MM/yyyy", "dd-MM-yyyy"]
            let formats = numericFormats + [
                "yyyy-MM-dd", "yyyy/MM/dd",
                "MMM d, yyyy", "MMMM d, yyyy", "MMM d yyyy", "MMMM d yyyy", "d MMM yyyy", "d MMMM yyyy"
            ]
            return formats.map { fmt in
                let df = DateFormatter()
                df.dateFormat = fmt
                df.locale = Locale(identifier: "en_US_POSIX")
                return df
            }
        }()
        
        for line in lines {
            let text = line.text
            for pattern in datePatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                    let nsStr = text as NSString
                    let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsStr.length))
                    for match in matches {
                        let matchedStr = nsStr.substring(with: match.range)
                        for df in formatters {
                            if let parsed = df.date(from: matchedStr) {
                                // Sanity check date is not 20 years in future/past
                                let year = Calendar.current.component(.year, from: parsed)
                                if year >= 2000 && year <= 2035 {
                                    return parsed
                                }
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
    
    private func extractLineItems(from lines: [RecognizedLine], totalAmount: Double) -> [ReceiptLineItem] {
        var items: [ReceiptLineItem] = []
        let skipKeywords = ["total", "subtotal", "tax", "vat", "gst", "tip", "balance", "change", "visa", "cash", "mastercard", "card", "payment", "discount"]
        
        for line in lines {
            let text = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = text.lowercased()
            
            var containsSkip = false
            for kw in skipKeywords {
                if lower.contains(kw) {
                    containsSkip = true
                    break
                }
            }
            if containsSkip { continue }
            
            // Check if line contains a description on left and an amount on right (e.g. "Latte 4.50" or "Avocado Toast $12.00")
            let pattern = #"^(.+?)\s+[\$€£₹¥]?\s*([0-9]+(?:\.[0-9]{2}))\s*$"#
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let nsStr = text as NSString
                if let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: nsStr.length)), match.numberOfRanges == 3 {
                    let desc = nsStr.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                    let amtStr = nsStr.substring(with: match.range(at: 2))
                    if let amt = Double(amtStr), amt > 0, amt < totalAmount + 0.01, desc.count >= 2 {
                        // Skip if desc is purely digits/symbols
                        if desc.rangeOfCharacter(from: .letters) != nil {
                            items.append(ReceiptLineItem(name: desc.capitalized, amount: amt))
                        }
                    }
                }
            }
        }
        
        return items
    }
    
    private func matchCategory(merchant: String, categories: [Category]) -> Category? {
        let merchantText = merchant.lowercased()
        
        // Keyword rule mappings
        let mapping: [(keywords: [String], categoryNames: [String])] = [
            (["grocery", "supermarket", "whole foods", "trader joe", "kroger", "walmart", "costco", "aldi", "safeway", "market", "food store"], ["Groceries", "Food", "Supermarket"]),
            (["starbucks", "cafe", "coffee", "restaurant", "burger", "pizza", "diner", "bakery", "bistro", "taco", "sushi", "grill", "bar", "kitchen", "chipotle", "mcdonald", "subway", "uber eats", "doordash"], ["Dining", "Food & Drink", "Restaurants", "Cafe", "Food"]),
            (["uber", "lyft", "shell", "chevron", "bp", "exxon", "gas", "fuel", "parking", "transit", "metro", "airline", "flight", "taxi"], ["Transportation", "Travel", "Fuel", "Auto"]),
            (["amazon", "target", "zara", "h&m", "nike", "apple store", "best buy", "clothing", "apparel", "boutique", "mall", "store"], ["Shopping", "Electronics", "General"]),
            (["cvs", "walgreens", "pharmacy", "clinic", "hospital", "doctor", "dental", "medicine"], ["Healthcare", "Health", "Medical", "Personal"]),
            (["cinema", "theatre", "steam", "playstation", "xbox", "netflix", "spotify", "hulu", "movie", "game"], ["Entertainment", "Subscriptions", "Leisure"]),
            (["electric", "water", "internet", "verizon", "at&t", "t-mobile", "power", "utility", "bill"], ["Bills", "Utilities", "Housing"])
        ]
        
        for rule in mapping {
            for kw in rule.keywords {
                if merchantText.contains(kw) {
                    for catName in rule.categoryNames {
                        if let matched = categories.first(where: { $0.label.localizedCaseInsensitiveContains(catName) }) {
                            return matched
                        }
                    }
                }
            }
        }
        
        // A receipt's address and item descriptions can suggest an unrelated category.
        for cat in categories {
            if merchantText.contains(cat.label.lowercased()) {
                return cat
            }
        }
        
        return nil
    }
    
    private func matchAccount(fullText: String, accounts: [Account]) -> Account? {
        let lines = fullText.components(separatedBy: "\n")
        let sourceIndex = lines.firstIndex { $0.range(of: #"(?i)\b(debited from|paid from|paid by|from account|credited to)\b"#, options: .regularExpression) != nil }
        let evidence = sourceIndex.map { lines[$0..<min($0 + 3, lines.count)].joined(separator: " ") } ?? fullText
        let lower = evidence.lowercased()
        let namedMatches = accounts.filter { account in
            let label = account.label.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !label.isEmpty else { return false }
            return evidence.range(of: #"(?i)(?<!\w)"# + NSRegularExpression.escapedPattern(for: label) + #"(?!\w)"#, options: .regularExpression) != nil
        }
        if namedMatches.count == 1 { return namedMatches[0] }
        if namedMatches.count > 1 { return nil }
        if lower.range(of: #"\bcash\b"#, options: .regularExpression) != nil {
            return accounts.first(where: { $0.type == .cash })
        }
        if lower.contains("amazon pay") {
            return accounts.first(where: { $0.type == .amazonPay })
        }
        if lower.contains("visa") || lower.contains("mastercard") || lower.contains("card") || lower.contains("bank") {
            let bankAccounts = accounts.filter { $0.type == .bank }
            return bankAccounts.count == 1 ? bankAccounts.first : nil
        }
        return nil
    }
    
    private func fallbackEmptyResult(currency: String, image: UIImage) -> ReceiptScanResult {
        ReceiptScanResult(
            merchantName: "Scanned Receipt",
            totalAmount: 0.0,
            currencySymbol: currency,
            date: Date(),
            suggestedCategoryId: nil,
            suggestedAccountId: nil,
            confidence: 0.0,
            lineItems: [],
            rawRecognizedText: "",
            receiptType: .general,
            originalImage: image,
            hasDetectedDate: false
        )
    }
}

// MARK: - CGImagePropertyOrientation Extension
private extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
