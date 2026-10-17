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
    var detectedCurrencySymbol: String? = nil
    
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
        allowsIntelligence: Bool = true,
        onIntelligenceStarted: (() -> Void)? = nil
    ) async -> ReceiptScanResult {
        await scanImages(
            [image],
            categories: categories,
            accounts: accounts,
            defaultCurrencySymbol: defaultCurrencySymbol,
            allowsIntelligence: allowsIntelligence,
            onIntelligenceStarted: onIntelligenceStarted
        )
    }

    /// Document camera scans can contain several pages; read all of them before parsing.
    func scanImages(
        _ images: [UIImage],
        categories: [Category],
        accounts: [Account],
        defaultCurrencySymbol: String = "$",
        allowsIntelligence: Bool = true,
        onIntelligenceStarted: (() -> Void)? = nil
    ) async -> ReceiptScanResult {
        guard let firstImage = images.first else {
            return fallbackEmptyResult(currency: defaultCurrencySymbol, image: UIImage())
        }

        var recognizedLines: [RecognizedLine] = []
        var hasConflictingTotals = false
        for image in images {
            let cgImage = image.cgImage ?? image.ciImage.flatMap {
                CIContext().createCGImage($0, from: $0.extent)
            }
            guard let cgImage else { continue }
            let orientation = CGImagePropertyOrientation(image.imageOrientation)
            var pageLines = await performVisionOCR(on: cgImage, orientation: orientation)
            var workingImage = cgImage
            var workingOrientation = orientation
            let verticalLines = pageLines.filter { $0.text.count >= 5 && $0.boundingBox.height > $0.boundingBox.width * 1.2 }.count
            if verticalLines > max(2, pageLines.count / 4) {
                for turn in [CGImagePropertyOrientation.left, .right] {
                    guard let rotated = await Task.detached(priority: .userInitiated, operation: {
                        ReceiptImagePreprocessor.rotatedImage(cgImage, orientation: orientation, quarterTurn: turn)
                    }).value else { continue }
                    let retry = await performVisionOCR(on: rotated, orientation: .up)
                    if retry.count >= pageLines.count / 2 && retry.contains(where: { $0.text.count >= 5 && $0.boundingBox.width > $0.boundingBox.height * 2 }) {
                        pageLines = retry
                        workingImage = rotated
                        workingOrientation = .up
                        break
                    }
                }
            }
            let originalText = pageLines.map(\.text).joined(separator: "\n")
            let originalEvidence = amountEvidence(pageLines)
            if !ReceiptAmountParser.isPaymentScreenshot(originalText),
               originalEvidence.amount == 0 || originalEvidence.priority < 50 || extractMerchantName(from: pageLines, receiptType: .physicalReceipt) == "Merchant",
               let prepared = await Task.detached(priority: .userInitiated, operation: { [workingImage, workingOrientation] in
                   ReceiptImagePreprocessor.documentImage(workingImage, orientation: workingOrientation)
               }).value {
                let retry = await performVisionOCR(on: prepared, orientation: .up)
                let retryEvidence = amountEvidence(retry)
                if originalEvidence.amount > 0, retryEvidence.amount > 0,
                   originalEvidence.priority == retryEvidence.priority, originalEvidence.priority >= 30,
                   abs(originalEvidence.amount - retryEvidence.amount) > 0.01 {
                    hasConflictingTotals = true
                } else if retryEvidence.amount > 0 && (originalEvidence.amount == 0 || retryEvidence.priority > originalEvidence.priority)
                            || (retryEvidence.amount == originalEvidence.amount && retry.count > pageLines.count) {
                    // Keep one coordinate space; never mix cropped and original OCR geometry.
                    pageLines = retry
                }
            }
            let indianPayment = pageLines.contains { $0.text.range(of: #"(?i)phonepe|paytm|google pay|gpay|\bupi\b|\binr\b"#, options: .regularExpression) != nil }
            if indianPayment {
                // Vision can recognize the rupee glyph as the visually similar hryvnia glyph.
                pageLines = pageLines.map { line in
                    RecognizedLine(text: ReceiptOCRCurrencyRepair.repairIndianPaymentGlyph(line.text),
                                   boundingBox: line.boundingBox, confidence: line.confidence)
                }
            }
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
        return await parsedResult(from: recognizedLines, originalImage: firstImage, categories: categories,
            accounts: accounts, defaultCurrencySymbol: defaultCurrencySymbol, allowsIntelligence: allowsIntelligence,
            hasConflictingTotals: hasConflictingTotals, onIntelligenceStarted: onIntelligenceStarted)
    }

    func scanText(_ text: String, categories: [Category], accounts: [Account],
                  defaultCurrencySymbol: String) async -> ReceiptScanResult {
        let lines = text.components(separatedBy: .newlines).map {
            RecognizedLine(text: ReceiptOCRCurrencyRepair.repairIndianPaymentGlyph($0.trimmingCharacters(in: .whitespacesAndNewlines)),
                           boundingBox: .zero, confidence: 1)
        }.filter { !$0.text.isEmpty }
        return await parsedResult(from: lines, originalImage: nil, categories: categories, accounts: accounts,
            defaultCurrencySymbol: defaultCurrencySymbol, allowsIntelligence: false,
            hasConflictingTotals: false, onIntelligenceStarted: nil)
    }

    private func parsedResult(from recognizedLines: [RecognizedLine], originalImage: UIImage?,
                              categories: [Category], accounts: [Account], defaultCurrencySymbol: String,
                              allowsIntelligence: Bool, hasConflictingTotals: Bool,
                              onIntelligenceStarted: (() -> Void)?) async -> ReceiptScanResult {
        let fullText = recognizedLines.map { $0.text }.joined(separator: "\n")
        
        // 1. Detect Receipt Type
        let receiptType = detectReceiptType(from: recognizedLines, fullText: fullText)
        
        // 2. Extract Currency & Amount
        let (extractedAmount, detectedCurrency) = extractTotalAmount(from: recognizedLines)
        var totalAmount = extractedAmount
        if hasConflictingTotals { totalAmount = 0 }
        
        let paymentStatus = ReceiptPaymentStatus.detect(in: fullText)
        var wasAssistedByAppleIntelligence = false
        if allowsIntelligence, totalAmount == 0, !hasConflictingTotals, paymentStatus != .pending, paymentStatus != .failed,
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
        let detectedDate = extractDate(from: recognizedLines, dayFirst: (detectedCurrency ?? defaultCurrencySymbol) == "₹")
        let date = detectedDate ?? Date()
        
        // 5. Extract Line Items
        let lineItems = extractLineItems(from: recognizedLines, totalAmount: totalAmount)
        
        // 6. Match Category & Account
        let transactionType: TransactionType = receiptType == .paymentScreenshot && fullText.range(
            of: #"(?i)\b(received from|money received|payment received|(?m)^received$)\b"#,
            options: .regularExpression) != nil ? .income : .expense
        let suggestedCategoryID = ReceiptCategoryMatcher.categoryID(
            merchant: merchantName,
            receiptText: receiptType == .paymentScreenshot ? "" : fullText,
            categories: categories.filter { $0.type == transactionType && !$0.isHidden }
                .map { .init(id: $0.id, label: $0.label) }
        )
        let suggestedAccount = matchAccount(fullText: fullText, accounts: accounts)
        
        // Calculate Confidence score
        var confidenceScore = 0.5
        if totalAmount > 0 { confidenceScore += 0.25 }
        if !merchantName.isEmpty && merchantName != "Merchant" { confidenceScore += 0.15 }
        if !lineItems.isEmpty { confidenceScore += 0.10 }
        
        return ReceiptScanResult(
            merchantName: merchantName.isEmpty || merchantName == "Merchant" ? "Scanned Receipt" : merchantName,
            totalAmount: totalAmount,
            // Settings owns the ledger currency. OCR currency hints only help parse the receipt.
            currencySymbol: defaultCurrencySymbol,
            date: date,
            suggestedCategoryId: suggestedCategoryID,
            suggestedAccountId: suggestedAccount?.id,
            confidence: min(1.0, confidenceScore),
            lineItems: lineItems,
            rawRecognizedText: fullText,
            receiptType: receiptType,
            originalImage: originalImage,
            wasAssistedByAppleIntelligence: wasAssistedByAppleIntelligence,
            transactionType: transactionType,
            paymentStatus: paymentStatus,
            hasDetectedDate: detectedDate != nil,
            detectedCurrencySymbol: detectedCurrency
        )
    }
    
    // MARK: - Vision OCR Runner
    private struct RecognizedLine {
        let text: String
        let boundingBox: CGRect
        let confidence: Float
        var unresolvedCurrencyGlyph: Bool = false
    }

    private func amountEvidence(_ lines: [RecognizedLine]) -> (amount: Double, priority: Int) {
        let parsed = lines.map { ReceiptAmountParser.Line(text: $0.text, bounds: $0.boundingBox, confidence: $0.confidence) }
        let amount = ReceiptAmountParser.total(in: parsed)
        return (amount, ReceiptAmountParser.candidates(in: parsed).filter { $0.amount == amount }.map(\.priority).max() ?? 0)
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
                // Group rows explicitly; a pairwise fuzzy comparator is not transitive.
                var rows: [[VNRecognizedTextObservation]] = []
                for observation in observations.sorted(by: { $0.boundingBox.midY > $1.boundingBox.midY }) {
                    if let last = rows.last, let first = last.first,
                       abs(first.boundingBox.midY - observation.boundingBox.midY) < min(first.boundingBox.height, observation.boundingBox.height) * 0.6 {
                        rows[rows.count - 1].append(observation)
                    } else {
                        rows.append([observation])
                    }
                }
                let sortedObservations = rows.flatMap { $0.sorted { $0.boundingBox.minX < $1.boundingBox.minX } }
                
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
            request.customWords = ["PhonePe", "Paytm", "Google Pay", "UPI", "INR", "UTR", "Grand Total", "Payable Amt", "Net Amount", "Bill Total", "CGST", "SGST", "GSTIN", "FSSAI", "Debited", "Credited", "Idli", "Dosa", "Paneer", "Biryani", "Gourmet", "Hospitality", "Collections", "Pvt. Ltd."]
            
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
        if ReceiptAmountParser.isPaymentScreenshot(fullText) ||
           lower.range(of: #"\b(apple\s+pay|venmo|zelle|cash\s+app)\b"#, options: .regularExpression) != nil {
            return .paymentScreenshot
        }
        if lower.contains("invoice") || lower.contains("bill to") || lower.contains("due date") {
            return .invoice
        }
        return .physicalReceipt
    }
    
    private func extractMerchantName(from lines: [RecognizedLine], receiptType: ReceiptType) -> String {
        ReceiptFieldParser.merchant(in: lines.map {
            ReceiptAmountParser.Line(text: $0.text, bounds: $0.boundingBox, confidence: $0.confidence)
        }, payment: receiptType == .paymentScreenshot)
    }

    private func extractTotalAmount(from lines: [RecognizedLine]) -> (Double, String?) {
        let parsedLines = lines.map { ReceiptAmountParser.Line(text: $0.text, bounds: $0.boundingBox, confidence: $0.confidence) }
        let amount = ReceiptAmountParser.total(in: parsedLines)
        let evidence = ReceiptAmountParser.candidates(in: parsedLines)
            .filter { $0.amount == amount }.max(by: { $0.priority < $1.priority })?.evidence
        let currency = evidence.flatMap { detectCurrencySymbol(in: $0) }
            ?? parsedLines.compactMap { detectCurrencySymbol(in: $0.text) }.first
            ?? (parsedLines.contains { $0.text.range(of: #"(?i)\b(gstin|cgst|sgst|fssai)\b"#, options: .regularExpression) != nil } ? "₹" : nil)
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
        ReceiptFieldParser.date(in: lines.map {
            ReceiptAmountParser.Line(text: $0.text, bounds: $0.boundingBox, confidence: $0.confidence)
        }, dayFirst: dayFirst)
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
    
    private func matchAccount(fullText: String, accounts: [Account]) -> Account? {
        let lines = fullText.components(separatedBy: "\n")
        let sourceIndex = lines.firstIndex { $0.range(of: #"(?i)\b(debited from|paid from|paid by|from account|credited to)\b"#, options: .regularExpression) != nil }
        let tenderLines = lines.filter { line in
            guard line.range(of: #"(?i)\b(cash|visa|mastercard|credit\s+card|debit\s+card|payment\s*(mode|method)|tender|amazon\s+pay)\b"#, options: .regularExpression) != nil,
                  line.range(of: #"(?i)\b(customer|cashier|balance|change)\b"#, options: .regularExpression) == nil else { return false }
            return line.range(of: #"(?i)\bcash\s*(?:amount|amt)?\s*[:\-]?\s*[$₹]?\s*0(?:\.0+)?\s*$"#, options: .regularExpression) == nil
        }
        let evidence = sourceIndex.map { lines[$0..<min($0 + 3, lines.count)].joined(separator: " ") }
            ?? tenderLines.joined(separator: " ")
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
