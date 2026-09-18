//
//  NaturalLanguageTransactionParser.swift
//  Spendy
//
//  High-performance on-device natural language parser for spoken and typed expense logging.
//  Handles:
//  - Thousands separators ("15,000", "12,000", "1,50,000")
//  - Spoken word multipliers ("15 thousand", "15 thoug", "20k", "5 hundred", "2.5m", "1 lakh")
//  - Word numbers ("one", "two", "twelve", "twenty")
//  - Account matching ("using SBI", "on Card", "from Cash")
//  - Clean merchant/category titles without stopword junk ("using", "as expense", "on", "for")
//

import Foundation
import SwiftUI

struct ParsedTransactionDraft: Identifiable, Equatable {
    var id: UUID = UUID()
    var rawText: String
    var title: String
    var amount: Double
    var type: TransactionType
    var category: Category?
    var account: Account?
    var date: Date
    var confidence: Double
    var isSelected: Bool = true
    var isRecurringWeekly: Bool = false
    var isRecurringMonthly: Bool = false
    var notes: String = ""
    
    var isValid: Bool {
        amount > 0 && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

enum NaturalLanguageTransactionParser {
    
    /// Parses single or compound multi-item spoken phrases into drafts
    static func parseMultiple(
        text: String,
        categories: [Category],
        accounts: [Account],
        defaultAccount: Account? = nil
    ) -> [ParsedTransactionDraft] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        
        // 1. Normalize numbers & speech patterns
        let normalized = normalizeSpokenNumbers(text: trimmed)
        
        // 2. Split clauses on comma, semicolon, or conjunctions ("and", "plus", "then", "&")
        let splitPattern = #"(?:[,;]|\band\b|\bplus\b|\bthen\b|&)"#
        var candidateSegments: [String] = []
        
        if let regex = try? NSRegularExpression(pattern: splitPattern, options: .caseInsensitive) {
            let nsStr = normalized as NSString
            let matches = regex.matches(in: normalized, options: [], range: NSRange(location: 0, length: nsStr.length))
            
            var lastIndex = 0
            for match in matches {
                let range = NSRange(location: lastIndex, length: match.range.location - lastIndex)
                if range.length > 0 {
                    let seg = nsStr.substring(with: range).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !seg.isEmpty {
                        candidateSegments.append(seg)
                    }
                }
                lastIndex = match.range.location + match.range.length
            }
            if lastIndex < nsStr.length {
                let seg = nsStr.substring(from: lastIndex).trimmingCharacters(in: .whitespacesAndNewlines)
                if !seg.isEmpty {
                    candidateSegments.append(seg)
                }
            }
        }
        
        // Keep only segments that contain an amount
        let validSegments = candidateSegments.filter { seg in
            let (amt, _) = extractAmount(from: seg)
            return amt > 0
        }
        
        let segmentsToProcess = validSegments.count >= 2 ? validSegments : [normalized]
        
        var results: [ParsedTransactionDraft] = []
        for segment in segmentsToProcess {
            let draft = parseSingle(text: segment, originalRawText: trimmed, categories: categories, accounts: accounts, defaultAccount: defaultAccount)
            if draft.amount > 0 {
                results.append(draft)
            }
        }
        
        if results.isEmpty {
            let single = parseSingle(text: normalized, originalRawText: trimmed, categories: categories, accounts: accounts, defaultAccount: defaultAccount)
            return [single]
        }
        
        return results
    }
    
    static func parseSingle(
        text: String,
        originalRawText: String,
        categories: [Category],
        accounts: [Account],
        defaultAccount: Account? = nil
    ) -> ParsedTransactionDraft {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ParsedTransactionDraft(
                rawText: originalRawText,
                title: "",
                amount: 0,
                type: .expense,
                category: categories.first,
                account: defaultAccount ?? accounts.first,
                date: Date(),
                confidence: 0
            )
        }
        
        let lower = trimmed.lowercased()
        
        // 1. Detect Transaction Type (Income vs Expense)
        let incomeKeywords = [
            "salary", "paycheck", "income", "freelance", "refund", "deposit",
            "bonus", "dividend", "interest", "cashback", "grant", "stipend", "reimbursement"
        ]
        var detectedType: TransactionType = .expense
        for word in incomeKeywords {
            if lower.contains(word) {
                detectedType = .income
                break
            }
        }
        
        // 2. Extract Amount
        let (extractedAmount, cleanedWithoutAmount) = extractAmount(from: trimmed)
        
        // 3. Extract Recurrence
        var isWeekly = false
        var isMonthly = false
        var cleanedWithoutRecurrence = cleanedWithoutAmount
        if lower.contains("every week") || lower.contains("weekly") {
            isWeekly = true
            cleanedWithoutRecurrence = cleanedWithoutRecurrence.replacingOccurrences(of: "every week", with: " ", options: .caseInsensitive)
            cleanedWithoutRecurrence = cleanedWithoutRecurrence.replacingOccurrences(of: "weekly", with: " ", options: .caseInsensitive)
        } else if lower.contains("every month") || lower.contains("monthly") {
            isMonthly = true
            cleanedWithoutRecurrence = cleanedWithoutRecurrence.replacingOccurrences(of: "every month", with: " ", options: .caseInsensitive)
            cleanedWithoutRecurrence = cleanedWithoutRecurrence.replacingOccurrences(of: "monthly", with: " ", options: .caseInsensitive)
        }
        
        // 4. Extract Date (yesterday, today, X days ago)
        let (extractedDate, cleanedWithoutDate) = extractDate(from: cleanedWithoutRecurrence)
        
        // 5. Match Account
        let (matchedAccount, cleanedWithoutAccount) = matchAccount(from: cleanedWithoutDate, accounts: accounts)
        let resolvedAccount = matchedAccount ?? defaultAccount ?? accounts.first
        
        // 6. Match Category
        let (matchedCategory, cleanedWithoutCategory) = matchCategory(
            from: cleanedWithoutAccount,
            categories: categories,
            type: detectedType
        )
        let fallbackCategory = categories.first(where: { $0.type == detectedType && !$0.isHidden }) ?? categories.first
        let resolvedCategory = matchedCategory ?? fallbackCategory
        
        // 7. Clean Title
        var title = cleanTitle(from: cleanedWithoutCategory)
        if title.isEmpty {
            if let cat = resolvedCategory {
                title = cat.label
            } else {
                title = detectedType == .income ? "Income" : "Expense"
            }
        }
        
        title = title.prefix(1).uppercased() + title.dropFirst()
        
        var confidence: Double = 0.4
        if extractedAmount > 0 { confidence += 0.3 }
        if matchedCategory != nil { confidence += 0.2 }
        if matchedAccount != nil { confidence += 0.1 }
        
        return ParsedTransactionDraft(
            rawText: originalRawText,
            title: title,
            amount: extractedAmount,
            type: detectedType,
            category: resolvedCategory,
            account: resolvedAccount,
            date: extractedDate,
            confidence: min(1.0, confidence),
            isSelected: true,
            isRecurringWeekly: isWeekly,
            isRecurringMonthly: isMonthly,
            notes: cleanedWithoutCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
    
    // MARK: - Spoken Numbers Normalization
    private static func normalizeSpokenNumbers(text: String) -> String {
        var str = text.lowercased()
        
        // 1. Remove thousands separators in numbers: 15,000 -> 15000, 1,20,000 -> 120000
        if let commaRegex = try? NSRegularExpression(pattern: #"(\d+),(\d{3})\b"#) {
            str = commaRegex.stringByReplacingMatches(in: str, range: NSRange(location: 0, length: str.utf16.count), withTemplate: "$1$2")
        }
        if let indianCommaRegex = try? NSRegularExpression(pattern: #"(\d+),(\d{2}),(\d{3})\b"#) {
            str = indianCommaRegex.stringByReplacingMatches(in: str, range: NSRange(location: 0, length: str.utf16.count), withTemplate: "$1$2$3")
        }
        
        // 2. Word numbers to digits
        let wordNumbers: [String: String] = [
            "zero": "0", "one": "1", "two": "2", "three": "3", "four": "4",
            "five": "5", "six": "6", "seven": "7", "eight": "8", "nine": "9",
            "ten": "10", "eleven": "11", "twelve": "12", "thirteen": "13",
            "fourteen": "14", "fifteen": "15", "sixteen": "16", "seventeen": "17",
            "eighteen": "18", "nineteen": "19", "twenty": "20", "thirty": "30",
            "forty": "40", "fifty": "50", "sixty": "60", "seventy": "70",
            "eighty": "80", "ninety": "90"
        ]
        for (word, num) in wordNumbers {
            str = str.replacingOccurrences(of: "\\b\(word)\\b", with: num, options: .regularExpression)
        }
        
        // 3. Multipliers: "15 thousand", "15 thoug", "15 thous", "15k", "15 grand" -> "15000"
        let thousandRegex = try? NSRegularExpression(pattern: #"([0-9]+(?:\.[0-9]+)?)\s*(?:thousand|thoug|thous|grand|k)\b"#, options: .caseInsensitive)
        if let matches = thousandRegex?.matches(in: str, range: NSRange(location: 0, length: str.utf16.count)) {
            for match in matches.reversed() {
                if let numRange = Range(match.range(at: 1), in: str),
                   let fullRange = Range(match.range, in: str),
                   let val = Double(str[numRange]) {
                    let total = Int(val * 1000)
                    str.replaceSubrange(fullRange, with: "\(total)")
                }
            }
        }
        
        // 4. Hundred: "5 hundred" -> "500"
        let hundredRegex = try? NSRegularExpression(pattern: #"([0-9]+(?:\.[0-9]+)?)\s*hundred\b"#, options: .caseInsensitive)
        if let matches = hundredRegex?.matches(in: str, range: NSRange(location: 0, length: str.utf16.count)) {
            for match in matches.reversed() {
                if let numRange = Range(match.range(at: 1), in: str),
                   let fullRange = Range(match.range, in: str),
                   let val = Double(str[numRange]) {
                    let total = Int(val * 100)
                    str.replaceSubrange(fullRange, with: "\(total)")
                }
            }
        }
        
        // 5. Lakh / Lac: "2 lakh" -> "200000"
        let lakhRegex = try? NSRegularExpression(pattern: #"([0-9]+(?:\.[0-9]+)?)\s*(?:lakh|lac)\b"#, options: .caseInsensitive)
        if let matches = lakhRegex?.matches(in: str, range: NSRange(location: 0, length: str.utf16.count)) {
            for match in matches.reversed() {
                if let numRange = Range(match.range(at: 1), in: str),
                   let fullRange = Range(match.range, in: str),
                   let val = Double(str[numRange]) {
                    let total = Int(val * 100_000)
                    str.replaceSubrange(fullRange, with: "\(total)")
                }
            }
        }
        
        // 6. Million: "1.5 million" -> "1500000"
        let millionRegex = try? NSRegularExpression(pattern: #"([0-9]+(?:\.[0-9]+)?)\s*(?:million|m)\b"#, options: .caseInsensitive)
        if let matches = millionRegex?.matches(in: str, range: NSRange(location: 0, length: str.utf16.count)) {
            for match in matches.reversed() {
                if let numRange = Range(match.range(at: 1), in: str),
                   let fullRange = Range(match.range, in: str),
                   let val = Double(str[numRange]) {
                    let total = Int(val * 1_000_000)
                    str.replaceSubrange(fullRange, with: "\(total)")
                }
            }
        }
        
        return str
    }
    
    // MARK: - Amount Extraction
    private static func extractAmount(from text: String) -> (Double, String) {
        let pattern = #"(?:[\$€£₹¥]|rs\.?|inr|usd|eur)?\s*([0-9]+(?:\.[0-9]{1,2})?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return (0, text)
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        var bestAmount: Double = 0
        var matchedRange: NSRange? = nil
        
        for match in matches.reversed() {
            if match.numberOfRanges > 1 {
                let numberString = nsString.substring(with: match.range(at: 1))
                if let val = Double(numberString), val > 0 {
                    bestAmount = val
                    matchedRange = match.range
                    break
                }
            }
        }
        
        var remaining = text
        if let range = matchedRange {
            remaining = nsString.replacingCharacters(in: range, with: " ")
        }
        
        return (bestAmount, remaining)
    }
    
    // MARK: - Date Extraction
    private static func extractDate(from text: String) -> (Date, String) {
        let lower = text.lowercased()
        let calendar = Calendar.current
        var targetDate = Date()
        var remaining = text
        
        if lower.contains("yesterday") {
            targetDate = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            remaining = remaining.replacingOccurrences(of: "yesterday", with: " ", options: .caseInsensitive)
        } else if lower.contains("day before yesterday") {
            targetDate = calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date()
            remaining = remaining.replacingOccurrences(of: "day before yesterday", with: " ", options: .caseInsensitive)
        } else if lower.contains("today") {
            targetDate = Date()
            remaining = remaining.replacingOccurrences(of: "today", with: " ", options: .caseInsensitive)
        } else if let daysAgoMatch = lower.range(of: #"([0-9]+)\s+days?\s+ago"#, options: .regularExpression) {
            let matchedStr = String(lower[daysAgoMatch])
            let numStr = matchedStr.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            if let count = Int(numStr) {
                targetDate = calendar.date(byAdding: .day, value: -count, to: Date()) ?? Date()
                remaining = remaining.replacingCharacters(in: daysAgoMatch, with: " ")
            }
        }
        
        return (targetDate, remaining)
    }
    
    // MARK: - Account Matching
    private static func matchAccount(from text: String, accounts: [Account]) -> (Account?, String) {
        let lower = text.lowercased()
        var remaining = text
        
        for account in accounts {
            let accLabel = account.label.lowercased()
            if lower.contains(accLabel) {
                remaining = remaining.replacingOccurrences(of: accLabel, with: " ", options: .caseInsensitive)
                return (account, remaining)
            }
        }
        
        // Common bank/account acronyms & names
        let commonKeywords = ["sbi", "hdfc", "icici", "chase", "citi", "amex", "cash", "credit card", "card", "bank", "checking"]
        for kw in commonKeywords {
            if lower.contains(kw) {
                let match = accounts.first(where: { $0.label.lowercased().contains(kw) })
                remaining = remaining.replacingOccurrences(of: kw, with: " ", options: .caseInsensitive)
                return (match, remaining)
            }
        }
        
        return (nil, remaining)
    }
    
    // MARK: - Category Matching
    private static func matchCategory(
        from text: String,
        categories: [Category],
        type: TransactionType
    ) -> (Category?, String) {
        let lower = text.lowercased()
        let remaining = text
        
        for category in categories where category.type == type && !category.isHidden {
            let catName = category.label.lowercased()
            if lower.contains(catName) {
                return (category, remaining)
            }
        }
        
        let categoryKeywords: [String: [String]] = [
            "Food & Drinks": [
                "coffee", "starbucks", "latte", "cappuccino", "cafe", "tea", "boba", "espresso",
                "dinner", "lunch", "breakfast", "brunch", "restaurant", "burger", "pizza", "sushi",
                "tacos", "bar", "drinks", "cocktails", "mcdonalds", "chipotle", "subway", "snack",
                "bakery", "food", "eat", "dining", "meal", "takeout", "uber eats", "doordash"
            ],
            "Groceries": [
                "grocery", "groceries", "supermarket", "trader joe", "whole foods", "walmart",
                "target", "costco", "aldi", "kroger", "safeway", "milk", "vegetables", "fruits", "market"
            ],
            "Transport": [
                "fuel", "petrol", "gas", "diesel", "taxi", "uber", "lyft", "cab", "parking",
                "toll", "metro", "subway", "train", "bus", "flight", "airline", "transit", "car wash", "ride-hailing"
            ],
            "Shopping": [
                "amazon", "shopping", "clothes", "shoes", "sneakers", "zara", "nike", "h&m", "apple store",
                "electronics", "gadget", "mall", "book", "books", "game", "steam", "app store"
            ],
            "Entertainment": [
                "movie", "cinema", "netflix", "spotify", "concert", "ticket", "theatre", "bowling",
                "disney", "hulu", "hbo", "party", "club", "gaming", "arcade"
            ],
            "Bills & Utilities": [
                "electricity", "water", "gas bill", "utility", "utilities", "wifi", "internet",
                "broadband", "phone bill", "mobile", "verizon", "at&t", "t-mobile", "recharge"
            ],
            "Health & Fitness": [
                "gym", "fitness", "workout", "doctor", "pharmacy", "medicine", "dentist", "hospital",
                "meds", "vitamins", "therapy", "yoga", "clinic"
            ],
            "Housing": [
                "rent", "mortgage", "maintenance", "furniture", "ikea", "repairs", "plumber", "home"
            ],
            "Salary": [
                "salary", "paycheck", "wages", "employer", "acme", "company"
            ],
            "Freelance": [
                "freelance", "client", "upwork", "fiverr", "contract", "consulting", "gig"
            ]
        ]
        
        for (categoryKey, keywords) in categoryKeywords {
            for kw in keywords {
                if lower.contains(kw) {
                    if let match = categories.first(where: {
                        $0.type == type && (
                            $0.label.lowercased().contains(categoryKey.lowercased()) ||
                            categoryKey.lowercased().contains($0.label.lowercased()) ||
                            $0.label.lowercased().contains(kw)
                        )
                    }) {
                        return (match, remaining)
                    }
                }
            }
        }
        
        return (nil, remaining)
    }
    
    // MARK: - Clean Title
    private static func cleanTitle(from text: String) -> String {
        let stopwords: Set<String> = [
            "at", "on", "for", "in", "to", "from", "using", "as", "expense", "income",
            "paid", "spent", "bought", "got", "via", "with", "the", "a", "an",
            "dollars", "bucks", "rs", "rupees", "eur", "usd", "and", "then", "plus",
            "every", "week", "month", "thousand", "k", "hundred", "million", "lakh"
        ]
        
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .filter { word in
                let w = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
                return !stopwords.contains(w) && !w.allSatisfy { $0.isNumber || $0.isPunctuation }
            }
        
        return words.joined(separator: " ").trimmingCharacters(in: .punctuationCharacters)
    }
}
