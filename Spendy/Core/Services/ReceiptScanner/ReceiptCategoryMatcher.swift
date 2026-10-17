import Foundation

/// Suggestions use merchant and purchased-item evidence, never a mandatory default.
enum ReceiptCategoryMatcher {
    struct Option {
        let id: String
        let label: String
    }

    private struct Rule {
        let categories: [String]
        let merchants: [String]
        let items: [String]
    }

    private static let rules: [Rule] = [
        .init(categories: ["food_delivery", "Food Delivery", "Food", "Food & Drink"],
              merchants: ["swiggy", "zomato", "uber eats", "doordash", "deliveroo"], items: []),
        .init(categories: ["groceries", "Groceries", "Supermarket", "Food"],
              merchants: ["market", "supermarket", "grocery", "groceries", "dmart", "reliance fresh", "bigbasket", "whole foods", "trader joe", "kroger", "costco", "aldi", "safeway"],
              items: ["atta", "basmati", "detergent", "biscuits", "vegetables", "rice kg", "milk"]),
        .init(categories: ["coffee", "Coffee & Cafés", "Cafe", "Coffee", "Food & Drink", "Food"],
              merchants: ["starbucks", "cafe", "café", "coffee", "costa"],
              items: ["espresso", "cappuccino", "latte", "americano"]),
        .init(categories: ["restaurants", "Restaurants", "Dining", "Food & Drink", "Food"],
              merchants: ["restaurant", "deli", "bistro", "bakery", "kitchen", "grill", "pizza", "burger", "pista house", "brahmins", "chats"],
              items: ["dine in", "dinein", "take away", "takeaway", "idli", "dosa", "paneer", "noodles", "masalapuri", "bhelpuri", "burger", "sandwich", "naan", "biryani", "manchurian", "mocktail", "chilli chicken", "fries", "pizza"]),
        .init(categories: ["clothing", "Clothing", "Apparel", "Shopping"],
              merchants: ["zara", "h&m", "apparel", "clothing", "boutique"],
              items: ["gents", "sweat", "shirt", "trouser", "jeans", "kurta", "saree", "dress"]),
        .init(categories: ["fuel", "Fuel", "Transportation", "Transport"],
              merchants: ["shell", "chevron", "exxon", "petrol", "bharat petroleum", "indian oil", "hindustan petroleum"],
              items: ["petrol", "diesel", "fuel volume", "litres"]),
        .init(categories: ["taxi", "Taxi & Ride-hailing", "Transportation", "Transport", "Travel"],
              merchants: ["uber", "lyft", "ola cabs", "taxi"], items: ["trip fare", "ride fare"]),
        .init(categories: ["health", "Health & Fitness", "Healthcare", "Medical"],
              merchants: ["pharmacy", "clinic", "hospital", "walgreens", "cvs", "apollo pharmacy"],
              items: ["prescription", "paracetamol", "tablets"]),
        .init(categories: ["shopping", "Shopping", "Electronics"],
              merchants: ["amazon", "target", "best buy", "apple store", "nike"], items: ["headphones", "charger", "laptop"]),
        .init(categories: ["public_transport", "Public Transport", "Transportation", "Transport"],
              merchants: ["metro", "transit", "railways"], items: ["bus ticket", "train ticket"]),
        .init(categories: ["travel", "Travel"], merchants: ["airline", "airlines", "indigo", "air india"], items: ["flight ticket"]),
        .init(categories: ["entertainment", "Entertainment", "Leisure"],
              merchants: ["cinema", "theatre", "steam", "playstation", "xbox"], items: ["movie ticket"]),
        .init(categories: ["subscriptions", "Subscriptions", "Entertainment"],
              merchants: ["netflix", "spotify", "hulu"], items: []),
        .init(categories: ["utilities", "Utilities", "Bills", "Housing"],
              merchants: ["electricity", "electric", "utility", "water board", "power company"], items: []),
        .init(categories: ["internet_mobile", "Internet & Mobile", "Utilities", "Bills"],
              merchants: ["verizon", "at&t", "t-mobile", "airtel", "jio"], items: [])
    ]

    static func categoryID(merchant: String, receiptText: String, categories: [Option]) -> String? {
        let merchant = normalized(merchant)
        let body = normalized(receiptText.components(separatedBy: .newlines)
            .filter { !ReceiptAmountParser.isIdentifierLine($0) }
            .joined(separator: " "))
        var scores: [String: Int] = [:]
        for rule in rules {
            let merchantHits = rule.merchants.count { contains($0, in: merchant) }
            let itemHits = rule.items.count { contains($0, in: body) }
            let score = merchantHits > 0 ? 20 + merchantHits * 2 + min(itemHits, 6) : min(itemHits, 6) * 2
            guard score >= 2 else { continue }
            // Prefer the specific existing category, then an explicitly named general fallback.
            let match = rule.categories.lazy.compactMap { name in
                categories.first { normalized($0.id) == normalized(name) || normalized($0.label) == normalized(name) }
            }.first
            if let match { scores[match.id] = max(scores[match.id] ?? 0, score) }
        }
        let ranked = scores.sorted { $0.value > $1.value }
        guard let best = ranked.first,
              ranked.count == 1 || best.value > ranked[1].value else { return nil }
        return best.key
    }

    private static func normalized(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .replacingOccurrences(of: #"[^\p{L}\p{N}]+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func contains(_ keyword: String, in text: String) -> Bool {
        (" " + text + " ").contains(" " + normalized(keyword) + " ")
    }
}
